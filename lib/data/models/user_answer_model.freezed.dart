// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_answer_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserAnswer _$UserAnswerFromJson(Map<String, dynamic> json) {
  return _UserAnswer.fromJson(json);
}

/// @nodoc
mixin _$UserAnswer {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get questionId => throw _privateConstructorUsedError;
  int get selectedAnswerIndex => throw _privateConstructorUsedError;
  int get correctAnswerIndex => throw _privateConstructorUsedError;
  bool get isCorrect => throw _privateConstructorUsedError;
  String get questionMode =>
      throw _privateConstructorUsedError; // 'practice' or 'exam'
  String get questionType =>
      throw _privateConstructorUsedError; // 'grammar' or 'vocabulary'
  int get difficultyLevel => throw _privateConstructorUsedError;
  String get grammarPoint => throw _privateConstructorUsedError;
  String? get sessionId =>
      throw _privateConstructorUsedError; // For grouping answers in a session
  int? get timeSpentSeconds =>
      throw _privateConstructorUsedError; // Time spent on this question
  DateTime? get answeredAt => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserAnswerCopyWith<UserAnswer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserAnswerCopyWith<$Res> {
  factory $UserAnswerCopyWith(
          UserAnswer value, $Res Function(UserAnswer) then) =
      _$UserAnswerCopyWithImpl<$Res, UserAnswer>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String questionId,
      int selectedAnswerIndex,
      int correctAnswerIndex,
      bool isCorrect,
      String questionMode,
      String questionType,
      int difficultyLevel,
      String grammarPoint,
      String? sessionId,
      int? timeSpentSeconds,
      DateTime? answeredAt,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class _$UserAnswerCopyWithImpl<$Res, $Val extends UserAnswer>
    implements $UserAnswerCopyWith<$Res> {
  _$UserAnswerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? questionId = null,
    Object? selectedAnswerIndex = null,
    Object? correctAnswerIndex = null,
    Object? isCorrect = null,
    Object? questionMode = null,
    Object? questionType = null,
    Object? difficultyLevel = null,
    Object? grammarPoint = null,
    Object? sessionId = freezed,
    Object? timeSpentSeconds = freezed,
    Object? answeredAt = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      questionId: null == questionId
          ? _value.questionId
          : questionId // ignore: cast_nullable_to_non_nullable
              as String,
      selectedAnswerIndex: null == selectedAnswerIndex
          ? _value.selectedAnswerIndex
          : selectedAnswerIndex // ignore: cast_nullable_to_non_nullable
              as int,
      correctAnswerIndex: null == correctAnswerIndex
          ? _value.correctAnswerIndex
          : correctAnswerIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isCorrect: null == isCorrect
          ? _value.isCorrect
          : isCorrect // ignore: cast_nullable_to_non_nullable
              as bool,
      questionMode: null == questionMode
          ? _value.questionMode
          : questionMode // ignore: cast_nullable_to_non_nullable
              as String,
      questionType: null == questionType
          ? _value.questionType
          : questionType // ignore: cast_nullable_to_non_nullable
              as String,
      difficultyLevel: null == difficultyLevel
          ? _value.difficultyLevel
          : difficultyLevel // ignore: cast_nullable_to_non_nullable
              as int,
      grammarPoint: null == grammarPoint
          ? _value.grammarPoint
          : grammarPoint // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: freezed == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String?,
      timeSpentSeconds: freezed == timeSpentSeconds
          ? _value.timeSpentSeconds
          : timeSpentSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      answeredAt: freezed == answeredAt
          ? _value.answeredAt
          : answeredAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserAnswerImplCopyWith<$Res>
    implements $UserAnswerCopyWith<$Res> {
  factory _$$UserAnswerImplCopyWith(
          _$UserAnswerImpl value, $Res Function(_$UserAnswerImpl) then) =
      __$$UserAnswerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String questionId,
      int selectedAnswerIndex,
      int correctAnswerIndex,
      bool isCorrect,
      String questionMode,
      String questionType,
      int difficultyLevel,
      String grammarPoint,
      String? sessionId,
      int? timeSpentSeconds,
      DateTime? answeredAt,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class __$$UserAnswerImplCopyWithImpl<$Res>
    extends _$UserAnswerCopyWithImpl<$Res, _$UserAnswerImpl>
    implements _$$UserAnswerImplCopyWith<$Res> {
  __$$UserAnswerImplCopyWithImpl(
      _$UserAnswerImpl _value, $Res Function(_$UserAnswerImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? questionId = null,
    Object? selectedAnswerIndex = null,
    Object? correctAnswerIndex = null,
    Object? isCorrect = null,
    Object? questionMode = null,
    Object? questionType = null,
    Object? difficultyLevel = null,
    Object? grammarPoint = null,
    Object? sessionId = freezed,
    Object? timeSpentSeconds = freezed,
    Object? answeredAt = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_$UserAnswerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      questionId: null == questionId
          ? _value.questionId
          : questionId // ignore: cast_nullable_to_non_nullable
              as String,
      selectedAnswerIndex: null == selectedAnswerIndex
          ? _value.selectedAnswerIndex
          : selectedAnswerIndex // ignore: cast_nullable_to_non_nullable
              as int,
      correctAnswerIndex: null == correctAnswerIndex
          ? _value.correctAnswerIndex
          : correctAnswerIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isCorrect: null == isCorrect
          ? _value.isCorrect
          : isCorrect // ignore: cast_nullable_to_non_nullable
              as bool,
      questionMode: null == questionMode
          ? _value.questionMode
          : questionMode // ignore: cast_nullable_to_non_nullable
              as String,
      questionType: null == questionType
          ? _value.questionType
          : questionType // ignore: cast_nullable_to_non_nullable
              as String,
      difficultyLevel: null == difficultyLevel
          ? _value.difficultyLevel
          : difficultyLevel // ignore: cast_nullable_to_non_nullable
              as int,
      grammarPoint: null == grammarPoint
          ? _value.grammarPoint
          : grammarPoint // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: freezed == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String?,
      timeSpentSeconds: freezed == timeSpentSeconds
          ? _value.timeSpentSeconds
          : timeSpentSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      answeredAt: freezed == answeredAt
          ? _value.answeredAt
          : answeredAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserAnswerImpl implements _UserAnswer {
  const _$UserAnswerImpl(
      {required this.id,
      required this.userId,
      required this.questionId,
      required this.selectedAnswerIndex,
      required this.correctAnswerIndex,
      required this.isCorrect,
      required this.questionMode,
      required this.questionType,
      required this.difficultyLevel,
      required this.grammarPoint,
      this.sessionId,
      this.timeSpentSeconds,
      this.answeredAt,
      final Map<String, dynamic>? metadata})
      : _metadata = metadata;

  factory _$UserAnswerImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserAnswerImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String questionId;
  @override
  final int selectedAnswerIndex;
  @override
  final int correctAnswerIndex;
  @override
  final bool isCorrect;
  @override
  final String questionMode;
// 'practice' or 'exam'
  @override
  final String questionType;
// 'grammar' or 'vocabulary'
  @override
  final int difficultyLevel;
  @override
  final String grammarPoint;
  @override
  final String? sessionId;
// For grouping answers in a session
  @override
  final int? timeSpentSeconds;
// Time spent on this question
  @override
  final DateTime? answeredAt;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'UserAnswer(id: $id, userId: $userId, questionId: $questionId, selectedAnswerIndex: $selectedAnswerIndex, correctAnswerIndex: $correctAnswerIndex, isCorrect: $isCorrect, questionMode: $questionMode, questionType: $questionType, difficultyLevel: $difficultyLevel, grammarPoint: $grammarPoint, sessionId: $sessionId, timeSpentSeconds: $timeSpentSeconds, answeredAt: $answeredAt, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserAnswerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.questionId, questionId) ||
                other.questionId == questionId) &&
            (identical(other.selectedAnswerIndex, selectedAnswerIndex) ||
                other.selectedAnswerIndex == selectedAnswerIndex) &&
            (identical(other.correctAnswerIndex, correctAnswerIndex) ||
                other.correctAnswerIndex == correctAnswerIndex) &&
            (identical(other.isCorrect, isCorrect) ||
                other.isCorrect == isCorrect) &&
            (identical(other.questionMode, questionMode) ||
                other.questionMode == questionMode) &&
            (identical(other.questionType, questionType) ||
                other.questionType == questionType) &&
            (identical(other.difficultyLevel, difficultyLevel) ||
                other.difficultyLevel == difficultyLevel) &&
            (identical(other.grammarPoint, grammarPoint) ||
                other.grammarPoint == grammarPoint) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.timeSpentSeconds, timeSpentSeconds) ||
                other.timeSpentSeconds == timeSpentSeconds) &&
            (identical(other.answeredAt, answeredAt) ||
                other.answeredAt == answeredAt) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      questionId,
      selectedAnswerIndex,
      correctAnswerIndex,
      isCorrect,
      questionMode,
      questionType,
      difficultyLevel,
      grammarPoint,
      sessionId,
      timeSpentSeconds,
      answeredAt,
      const DeepCollectionEquality().hash(_metadata));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserAnswerImplCopyWith<_$UserAnswerImpl> get copyWith =>
      __$$UserAnswerImplCopyWithImpl<_$UserAnswerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserAnswerImplToJson(
      this,
    );
  }
}

abstract class _UserAnswer implements UserAnswer {
  const factory _UserAnswer(
      {required final String id,
      required final String userId,
      required final String questionId,
      required final int selectedAnswerIndex,
      required final int correctAnswerIndex,
      required final bool isCorrect,
      required final String questionMode,
      required final String questionType,
      required final int difficultyLevel,
      required final String grammarPoint,
      final String? sessionId,
      final int? timeSpentSeconds,
      final DateTime? answeredAt,
      final Map<String, dynamic>? metadata}) = _$UserAnswerImpl;

  factory _UserAnswer.fromJson(Map<String, dynamic> json) =
      _$UserAnswerImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get questionId;
  @override
  int get selectedAnswerIndex;
  @override
  int get correctAnswerIndex;
  @override
  bool get isCorrect;
  @override
  String get questionMode;
  @override // 'practice' or 'exam'
  String get questionType;
  @override // 'grammar' or 'vocabulary'
  int get difficultyLevel;
  @override
  String get grammarPoint;
  @override
  String? get sessionId;
  @override // For grouping answers in a session
  int? get timeSpentSeconds;
  @override // Time spent on this question
  DateTime? get answeredAt;
  @override
  Map<String, dynamic>? get metadata;
  @override
  @JsonKey(ignore: true)
  _$$UserAnswerImplCopyWith<_$UserAnswerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
