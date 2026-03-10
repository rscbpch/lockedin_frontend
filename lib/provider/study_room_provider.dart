import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/study_room/study_room.dart';
import '../services/study_room_api_service.dart';

enum RoomStatus { idle, loading, success, error }

class StudyRoomProvider extends ChangeNotifier {
  final StudyRoomApiService _api;

  StudyRoomProvider(this._api);

  List<StudyRoom> _rooms = [];
  RoomStatus _status = RoomStatus.idle;
  String? _error;
  Timer? _pollTimer;

  List<StudyRoom> get rooms => _rooms;
  RoomStatus get status => _status;
  String? get error => _error;
  bool get isLoading => _status == RoomStatus.loading;

  // Expose JaaS App ID so MeetingScreen can build the room name
  String get jaasAppId => _api.jaasAppId;

  Future<void> fetchRooms() async {
    _status = RoomStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _rooms = await _api.getActiveRooms();
      _status = RoomStatus.success;
    } catch (e) {
      _error = e.toString();
      _status = RoomStatus.error;
    }
    notifyListeners();
  }

  void startPolling({Duration interval = const Duration(seconds: 15)}) {
    fetchRooms();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => fetchRooms());
  }

  void stopPolling() => _pollTimer?.cancel();

  Future<StudyRoom> createRoom(String name) async {
    final room = await _api.createRoom(name);
    _rooms = [room, ..._rooms];
    notifyListeners();
    return room;
  }

  Future<StudyRoom> joinRoom(String roomId) async {
    final updated = await _api.joinRoom(roomId);
    _rooms = _rooms.map((r) => r.roomId == roomId ? updated : r).toList();
    notifyListeners();
    return updated;
  }

  Future<void> leaveRoom(String roomId) async {
    await _api.leaveRoom(roomId);
    await fetchRooms();
  }

  Future<String> getJitsiToken({
    required String roomId,
    required String displayName,
    required String email,
    required String avatar, 
  }) async {
    return await _api.getJitsiToken(
      roomId: roomId,
      displayName: displayName,
      email: email,
      avatar: avatar,
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}