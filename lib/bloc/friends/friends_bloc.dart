import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maxim_chat/bloc/friends/friends_events.dart';
import 'package:maxim_chat/bloc/friends/friends_states.dart';
import 'package:maxim_chat/data/models/user.dart';
import 'package:maxim_chat/data/repositories/app_repository.dart';

class FriendsBloc extends Bloc<FriendsEvent, FriendsState> {
  final AppRepository appRepository;
  final String currentUserId;
  StreamSubscription? _friendsSubscription;
  StreamSubscription? _requestsSubscription;
  StreamSubscription? _sentRequestsSubscription;

  FriendsBloc({required this.appRepository, required this.currentUserId})
    : super(FriendsLoading()) {
    on<LoadFriendsEvent>(_onLoadFriends);
    on<SearchUsersEvent>(_onSearchUsers);
    on<SendFriendRequestEvent>(_onSendFriendRequest);
    on<AcceptFriendRequestEvent>(_onAcceptFriendRequest);
    on<RejectFriendRequestEvent>(_onRejectFriendRequest);
    on<RemoveFriendEvent>(_onRemoveFriend);
    on<CancelFriendRequestEvent>(_onCancelFriendRequest);
  }

  Future<void> _onLoadFriends(
    LoadFriendsEvent event,
    Emitter<FriendsState> emit,
  ) async {
    try {
      await _friendsSubscription?.cancel();
      await _requestsSubscription?.cancel();
      await _sentRequestsSubscription?.cancel();

      final friends = <User>[];
      final friendRequests = <User>[];
      final sentRequests = <User>[];

      _friendsSubscription = appRepository
          .friendsWithDetailsStream(event.userId)
          .listen((friendsList) {
            friends.clear();
            friends.addAll(friendsList);
            add(SearchUsersEvent(''));
          });

      _requestsSubscription = appRepository
          .friendRequestsStream(event.userId)
          .asyncMap((requestUids) async {
            final requests = <User>[];
            for (final uid in requestUids) {
              final user = await appRepository.userStream(uid).first;
              if (user != null) requests.add(user);
            }
            return requests;
          })
          .listen((requestsList) {
            friendRequests.clear();
            friendRequests.addAll(requestsList);
            add(SearchUsersEvent(''));
          });

      _sentRequestsSubscription = appRepository
          .friendSendsRequestsStream(event.userId)
          .asyncMap((sentUids) async {
            final sent = <User>[];
            for (final uid in sentUids) {
              final user = await appRepository.userStream(uid).first;
              if (user != null) sent.add(user);
            }
            return sent;
          })
          .listen((sentList) {
            sentRequests.clear();
            sentRequests.addAll(sentList);
            add(SearchUsersEvent(''));
          });

      emit(
        FriendsLoaded(
          friends: friends,
          friendRequests: friendRequests,
          sentRequests: sentRequests,
          searchResults: [],
        ),
      );
    } catch (e) {
      emit(FriendsError('Ошибка загрузки друзей: $e'));
    }
  }

  Future<void> _onSearchUsers(
    SearchUsersEvent event,
    Emitter<FriendsState> emit,
  ) async {
    if (state is FriendsLoaded) {
      final currentState = state as FriendsLoaded;

      if (event.query.isEmpty) {
        emit(currentState.copyWith(searchResults: []));
        return;
      }

      try {
        final searchResults = await appRepository
            .searchUsers(event.query)
            .first;
        final filteredResults = searchResults
            .where((user) => user.uid != currentUserId)
            .toList();

        emit(currentState.copyWith(searchResults: filteredResults));
      } catch (e) {
        emit(FriendsError('Ошибка поиска: $e'));
      }
    }
  }

  Future<void> _onSendFriendRequest(
    SendFriendRequestEvent event,
    Emitter<FriendsState> emit,
  ) async {
    try {
      await appRepository.sendFriendRequest(event.fromUid, event.toUid);
    } catch (e) {
      emit(FriendsError('Ошибка отправки запроса: $e'));
    }
  }

  Future<void> _onAcceptFriendRequest(
    AcceptFriendRequestEvent event,
    Emitter<FriendsState> emit,
  ) async {
    try {
      await appRepository.acceptFriendRequest(
        event.acceptorUid,
        event.requesterUid,
      );
    } catch (e) {
      emit(FriendsError('Ошибка принятия запроса: $e'));
    }
  }

  Future<void> _onRejectFriendRequest(
    RejectFriendRequestEvent event,
    Emitter<FriendsState> emit,
  ) async {
    try {
      await appRepository.rejectFriendRequest(
        event.rejectorUid,
        event.requesterUid,
      );
    } catch (e) {
      emit(FriendsError('Ошибка отклонения запроса: $e'));
    }
  }

  Future<void> _onRemoveFriend(
    RemoveFriendEvent event,
    Emitter<FriendsState> emit,
  ) async {
    try {
      await appRepository.removeFriend(event.uid1, event.uid2);
    } catch (e) {
      emit(FriendsError('Ошибка удаления друга: $e'));
    }
  }

  Future<void> _onCancelFriendRequest(
    CancelFriendRequestEvent event,
    Emitter<FriendsState> emit,
  ) async {
    try {
      await appRepository.cancelFriendRequest(event.fromUid, event.toUid);
    } catch (e) {
      emit(FriendsError('Ошибка отмены запроса: $e'));
    }
  }

  @override
  Future<void> close() {
    _friendsSubscription?.cancel();
    _requestsSubscription?.cancel();
    _sentRequestsSubscription?.cancel();
    return super.close();
  }
}

extension FriendsStateCopy on FriendsLoaded {
  FriendsLoaded copyWith({
    List<User>? friends,
    List<User>? friendRequests,
    List<User>? sentRequests,
    List<User>? searchResults,
  }) {
    return FriendsLoaded(
      friends: friends ?? this.friends,
      friendRequests: friendRequests ?? this.friendRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      searchResults: searchResults ?? this.searchResults,
    );
  }
}
