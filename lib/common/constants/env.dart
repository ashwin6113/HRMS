class Environment{
  static const String environment = String.fromEnvironment('environment', defaultValue: 'dev');
  static const String apiUrl = String.fromEnvironment('apiUrl');
}