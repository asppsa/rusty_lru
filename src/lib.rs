#[macro_use] extern crate rutie;
#[macro_use] extern crate lazy_static;

use lru::LruCache;
use std::ops::{Deref, DerefMut};
use rutie::{AnyObject, Class, Module, Array, Integer, Boolean, AnyException, GC, NilClass, Object, VM};
use rutie::types::Value;

pub struct HashableObject {
  value: Value,
  hash: i64
}

impl HashableObject {
  fn get_hash<T: Object>(object: &T) -> i64 {
    object.send("hash", &[])
      .try_convert_to::<Integer>()
      .map_err(|e| VM::raise_ex(e))
      .unwrap()
      .to_i64()
  }
}

impl<T: Object> From<&T> for HashableObject {
  fn from(object: &T) -> Self {
    Self {
      hash: Self::get_hash(object),
      value: object.value()
    }
  }
}

impl From<Value> for HashableObject {
  fn from(value: Value) -> Self {
    Self::from(&AnyObject::from(value))
  }
}

impl Object for HashableObject {
  #[inline]
  fn value(&self) -> Value {
    self.value
  }
}

impl PartialEq for HashableObject {
  fn eq(&self, other: &Self) -> bool {
    self.is_eql(other)
  }
}

impl Eq for HashableObject {}

impl std::hash::Hash for HashableObject {
  // Use the oject's hash if it has one; otherwise, fall back to object ID
  fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
    self.hash.hash(state);
  }
}

pub struct ObjectLruCache {
  inner: LruCache<HashableObject, AnyObject>,
}

impl ObjectLruCache {
  fn new(cap: usize) -> Self {
    ObjectLruCache { inner: LruCache::new(cap) }
  }

  fn unbounded() -> Self {
    ObjectLruCache { inner: LruCache::unbounded() }
  }

  fn get(&mut self, key: &AnyObject) -> Option<&AnyObject> {
    self.inner.get(&HashableObject::from(key))
  }

  fn put(&mut self, key: AnyObject, value: AnyObject) -> Option<AnyObject> {
    self.inner.put(HashableObject::from(&key), value)
  }

  fn pop(&mut self, key: &AnyObject) -> Option<AnyObject> {
    self.inner.pop(&HashableObject::from(key))
  }

  fn peek(&self, key: &AnyObject) -> Option<&AnyObject> {
    self.inner.peek(&HashableObject::from(key))
  }

  fn contains(&self, key: &AnyObject) -> bool {
    self.inner.contains(&HashableObject::from(key))
  }
}

impl Deref for ObjectLruCache {
  type Target = LruCache<HashableObject, AnyObject>;

  fn deref(&self) -> &LruCache<HashableObject, AnyObject> {
    &self.inner
  }
}

impl DerefMut for ObjectLruCache {
  fn deref_mut(&mut self) -> &mut LruCache<HashableObject, AnyObject> {
    &mut self.inner
  }
}

wrappable_struct! {
  ObjectLruCache,
  ObjectLruCacheWrapper,
  OBJECT_LRU_CACHE_WRAPPER,

  // Mark each `AnyObject` element of the `inner` cache to prevent garbage collection.
  // `data` is a mutable reference to the wrapped data (`&mut ObjectLruCache`).
  mark(cache) {
    for (key, value) in &cache.inner {
      GC::mark(key);
      GC::mark(value);
    }
  }
}

class!(Cache);

impl Cache {
  fn unwrap_or_raise<T>(result: Result<T, AnyException>) -> T {
    result
      .map_err(|e| VM::raise_ex(e))
      .unwrap()
  }

  fn cache(&self) -> &ObjectLruCache {
    self.get_data(&*OBJECT_LRU_CACHE_WRAPPER)
  }

  fn cache_mut(&mut self) -> &mut ObjectLruCache {
    self.get_data_mut(&*OBJECT_LRU_CACHE_WRAPPER)
  }

  fn array_from_pair(pair: (&HashableObject, &AnyObject)) -> Array {
    let mut array = Array::with_capacity(2);
    array.push(pair.0.to_any_object());
    array.push(pair.1.to_any_object());
    array
  }
}

methods! {
  Cache,
  itself,

  fn new(cap_result: Integer) -> AnyObject {
    let cache = match cap_result {
      Ok(number) => ObjectLruCache::new(number.to_u64() as usize),
      Err(_)     => ObjectLruCache::unbounded()
    };

    Class::from_existing("RustyLRU")
      .get_nested_class("Cache")
      .wrap_data(cache, &*OBJECT_LRU_CACHE_WRAPPER)
  }

  fn load(key: AnyObject) -> AnyObject {
    match itself.cache_mut().get(&Cache::unwrap_or_raise(key)) {
      Some(value) => value.to_any_object(),
      None        => NilClass::new().to_any_object()
    }
  }

  fn store(key: AnyObject, value: AnyObject) -> AnyObject {
    match itself.cache_mut().put(Cache::unwrap_or_raise(key), Cache::unwrap_or_raise(value)) {
      Some(value) => value.to_any_object(),
      None        => NilClass::new().to_any_object()
    }
  }

  fn delete(key: AnyObject) -> AnyObject {
    match itself.cache_mut().pop(&Cache::unwrap_or_raise(key)) {
      Some(value) => value,
      None        => NilClass::new().to_any_object()
    }
  }

  fn pop() -> AnyObject {
    match itself.cache_mut().pop_lru() {
      Some(pair) => Cache::array_from_pair((&pair.0, &pair.1)).to_any_object(),
      None       => NilClass::new().to_any_object()
    }
  }

  fn peek(key: AnyObject) -> AnyObject {
    match itself.cache().peek(&Cache::unwrap_or_raise(key)) {
      Some(value) => value.to_any_object(),
      None        => NilClass::new().to_any_object()
    }
  }

  fn lru_pair() -> AnyObject {
    match itself.cache().peek_lru() {
      Some(pair) => Cache::array_from_pair(pair).to_any_object(),
      None       => NilClass::new().to_any_object()
    }
  }

  fn has_key(key: AnyObject) -> Boolean {
    let contained = itself.cache().contains(&Cache::unwrap_or_raise(key));
    Boolean::new(contained)
  }

  fn is_empty() -> Boolean {
    let empty = itself.cache().is_empty();
    Boolean::new(empty)
  }

  fn length() -> Integer {
    let len = itself.cache().len();
    Integer::new(len as i64)
  }

  fn resize(cap: Integer) -> NilClass {
    itself.cache_mut().resize(Cache::unwrap_or_raise(cap).to_u64() as usize);
    NilClass::new()
  }

  fn clear() -> NilClass {
    itself.cache_mut().clear();
    NilClass::new()
  }

  fn each_pair() -> Cache {
    for pair in &itself.cache().inner {
      VM::yield_object(Cache::array_from_pair(pair));
    }
    itself
  }

  fn each_key() -> Cache {
    for (key, _) in &itself.cache().inner {
      VM::yield_object(key.to_any_object());
    }
    itself
  }

  fn each_value() -> Cache {
    for (_, value) in &itself.cache().inner {
      VM::yield_object(value.to_any_object());
    }
    itself
  }
}

#[allow(non_snake_case)]
#[no_mangle]
pub extern "C" fn Init_rusty_lru() {
  let parent = Class::from_existing("Object");
  Module::from_existing("RustyLRU")
    .define_nested_class("Cache", Some(&parent))
    .define(|itself| {
      itself.def_self("new", new);

      itself.def("[]", load);
      itself.def("[]=", store);
      itself.def("delete", delete);
      itself.def("pop", pop);
      itself.def("peek", peek);
      itself.def("lru_pair", lru_pair);
      itself.def("empty?", is_empty);
      itself.def("has_key?", has_key);
      itself.def("length", length);
      itself.def("resize", resize);
      itself.def("clear", clear);
      itself.def("each_pair", each_pair);
      itself.def("each_key", each_key);
      itself.def("each_value", each_value);
    });
}

#[cfg(test)]
mod tests {
  use super::*;
  use std::collections::hash_map::DefaultHasher;
  use std::hash::Hash;
  use std::hash::Hasher;
  use rutie::RString;

  #[test]
  fn test() {
    VM::init();

    /*
     * Test HashableObject hashes as intended
     */
    let nil = NilClass::new();
    let ho = HashableObject::from(&nil);

    let mut hasher1 = DefaultHasher::new();
    let mut hasher2 = DefaultHasher::new();

    nil.send("hash", &[]).try_convert_to::<Integer>().unwrap().to_i64().hash(&mut hasher1);
    ho.hash(&mut hasher2);

    let hash1 = hasher1.finish();
    let hash2 = hasher2.finish();
    assert_eq!(hash1, hash2);

    /*
     * Create a cache and make sure it works
     */
    let mut cache = ObjectLruCache::new(2);
    let key1 = RString::new_utf8("key1").to_any_object();
    let key2 = RString::new_utf8("key2").to_any_object();

    let val1 = RString::new_utf8("val1").to_any_object();
    let val2 = RString::new_utf8("val2").to_any_object();

    // We use to_any_object() to clone the reference to the ruby object, so that it can be put into
    // the cache
    assert_eq!(cache.put(key1.to_any_object(), val1.to_any_object()), None);
    // Returns the old value if there was one
    assert_eq!(cache.put(key1.to_any_object(), val2.to_any_object()), Some(val1));
    assert_eq!(cache.contains(&key1), true);

    // These have different caching behaviours, but should all return the same
    assert_eq!(cache.get(&key2), None);
    assert_eq!(cache.peek(&key2), None);
    assert_eq!(cache.pop(&key2), None);

    assert_eq!(cache.get(&key1), Some(&val2));
    assert_eq!(cache.peek(&key1), Some(&val2));
    assert_eq!(cache.pop(&key1), Some(val2));
    assert_eq!(cache.pop(&key1), None);
    assert_eq!(cache.peek(&key1), None);
  }
}
