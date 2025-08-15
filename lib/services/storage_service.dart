import 'package:desk_switch/models/profile.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage_service.g.dart';

@Riverpod(keepAlive: true)
class StorageService extends _$StorageService {
  static const String _serverProfileBox = 'server_profiles';
  static const String _clientProfileBox = 'client_profiles';

  @override
  void build() {}

  Future<void> saveServerProfile(ServerProfile profile) async {
    final box = await Hive.openBox<ServerProfile>(_serverProfileBox);
    await box.put(profile.name ?? 'default', profile);
  }

  Future<ServerProfile?> getServerProfile(String name) async {
    final box = await Hive.openBox<ServerProfile>(_serverProfileBox);
    return box.get(name);
  }

  Future<void> deleteServerProfile(String name) async {
    final box = await Hive.openBox<ServerProfile>(_serverProfileBox);
    await box.delete(name);
  }

  Future<void> saveClientProfile(ClientProfile profile) async {
    final box = await Hive.openBox<ClientProfile>(_clientProfileBox);
    await box.put(profile.name ?? 'default', profile);
  }

  Future<ClientProfile?> getClientProfile(String name) async {
    final box = await Hive.openBox<ClientProfile>(_clientProfileBox);
    return box.get(name);
  }

  Future<void> deleteClientProfile(String name) async {
    final box = await Hive.openBox<ClientProfile>(_clientProfileBox);
    await box.delete(name);
  }
}
