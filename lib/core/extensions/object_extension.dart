extension ObjectExtension<T extends Object> on T {
  U let<U>(U Function(T) f) => f(this);
}
