// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'question_analytics_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

QuestionAnalytics _$QuestionAnalyticsFromJson(Map<String, dynamic> json) {
  return _QuestionAnalytics.fromJson(json);
}

/// @nodoc
mixin _$QuestionAnalytics {
  String get questionId => throw _privateConstructorUsedError;
  int get totalAttempts => throw _privateConstructorUsedError;
  int get correctAttempts => throw _privateConstructorUsedError;
  int get wrongAttempts => throw _privateConstructorUsedError;
  double get correctPercentage => throw _privateConstructorUsedError;
  Map<String, int> get answerDistribution =>
      throw _privateConstructorUsedError; // {"0": 45, "1": 20, "2": 15, "3": 12}
  Map<String, double> get answerPercentages =>
      throw _privateConstructorUsedError; // {"0": 48.9, "1": 21.7, "2": 16.3, "3": 13.1}
  String get questionMode =>
      throw _privateConstructorUsedError; // 'practice' or 'exam'
  String get questionType =>
      throw _privateConstructorUsedError; // 'grammar' or 'vocabulary'
  int get difficultyLevel => throw _privateConstructorUsedError;
  String get grammarPoint => throw _privateConstructorUsedError;
  int? get averageTimeSeconds => throw _privateConstructorUsedError;
  DateTime? get lastUpdated => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QuestionAnalyticsCopyWith<QuestionAnalytics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestionAnalyticsCopyWith<$Res> {
  factory $QuestionAnalyticsCopyWith(
          QuestionAnalytics value, $Res Function(QuestionAnalytics) then) =
      _$QuestionAnalyticsCopyWithImpl<$Res, QuestionAnalytics>;
  @useResult
  $Res call(
      {String questionId,
      int totalAttempts,
      int correctAttempts,
      int wrongAttempts,
      double correctPercentage,
      Map<String, int> answerDistribution,
      Map<String, double> answerPercentages,
      String questionMode,
      String questionType,
      int difficultyLevel,
      String grammarPoint,
      int? averageTimeSeconds,
      DateTime? lastUpdated,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class _$QuestionAnalyticsCopyWithImpl<$Res, $Val extends QuestionAnalytics>
    implements $QuestionAnalyticsCopyWith<$Res> {
  _$QuestionAnalyticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questionId = null,
    Object? totalAttempts = null,
    Object? correctAttempts = null,
    Object? wrongAttempts = null,
    Object? correctPercentage = null,
    Object? answerDistribution = null,
    Object? answerPercentages = null,
    Object? questionMode = null,
    Object? questionType = null,
    Object? difficultyLevel = null,
    Object? grammarPoint = null,
    Object? averageTimeSeconds = freezed,
    Object? lastUpdated = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      questionId: null == questionId
          ? _value.questionId
          : questionId // ignore: cast_nullable_to_non_nullable
              as String,
      totalAttempts: null == totalAttempts
          ? _value.totalAttempts
          : totalAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      correctAttempts: null == correctAttempts
          ? _value.correctAttempts
          : correctAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      wrongAttempts: null == wrongAttempts
          ? _value.wrongAttempts
          : wrongAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      correctPercentage: null == correctPercentage
          ? _value.correctPercentage
          : correctPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      answerDistribution: null == answerDistribution
          ? _value.answerDistribution
          : answerDistribution // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      answerPercentages: null == answerPercentages
          ? _value.answerPercentages
          : answerPercentages // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
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
      averageTimeSeconds: freezed == averageTimeSeconds
          ? _value.averageTimeSeconds
          : averageTimeSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuestionAnalyticsImplCopyWith<$Res>
    implements $QuestionAnalyticsCopyWith<$Res> {
  factory _$$QuestionAnalyticsImplCopyWith(_$QuestionAnalyticsImpl value,
          $Res Function(_$QuestionAnalyticsImpl) then) =
      __$$QuestionAnalyticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String questionId,
      int totalAttempts,
      int correctAttempts,
      int wrongAttempts,
      double correctPercentage,
      Map<String, int> answerDistribution,
      Map<String, double> answerPercentages,
      String questionMode,
      String questionType,
      int difficultyLevel,
      String grammarPoint,
      int? averageTimeSeconds,
      DateTime? lastUpdated,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class __$$QuestionAnalyticsImplCopyWithImpl<$Res>
    extends _$QuestionAnalyticsCopyWithImpl<$Res, _$QuestionAnalyticsImpl>
    implements _$$QuestionAnalyticsImplCopyWith<$Res> {
  __$$QuestionAnalyticsImplCopyWithImpl(_$QuestionAnalyticsImpl _value,
      $Res Function(_$QuestionAnalyticsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questionId = null,
    Object? totalAttempts = null,
    Object? correctAttempts = null,
    Object? wrongAttempts = null,
    Object? correctPercentage = null,
    Object? answerDistribution = null,
    Object? answerPercentages = null,
    Object? questionMode = null,
    Object? questionType = null,
    Object? difficultyLevel = null,
    Object? grammarPoint = null,
    Object? averageTimeSeconds = freezed,
    Object? lastUpdated = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_$QuestionAnalyticsImpl(
      questionId: null == questionId
          ? _value.questionId
          : questionId // ignore: cast_nullable_to_non_nullable
              as String,
      totalAttempts: null == totalAttempts
          ? _value.totalAttempts
          : totalAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      correctAttempts: null == correctAttempts
          ? _value.correctAttempts
          : correctAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      wrongAttempts: null == wrongAttempts
          ? _value.wrongAttempts
          : wrongAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      correctPercentage: null == correctPercentage
          ? _value.correctPercentage
          : correctPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      answerDistribution: null == answerDistribution
          ? _value._answerDistribution
          : answerDistribution // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      answerPercentages: null == answerPercentages
          ? _value._answerPercentages
          : answerPercentages // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
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
      averageTimeSeconds: freezed == averageTimeSeconds
          ? _value.averageTimeSeconds
          : averageTimeSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
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
class _$QuestionAnalyticsImpl implements _QuestionAnalytics {
  const _$QuestionAnalyticsImpl(
      {required this.questionId,
      required this.totalAttempts,
      required this.correctAttempts,
      required this.wrongAttempts,
      required this.correctPercentage,
      required final Map<String, int> answerDistribution,
      required final Map<String, double> answerPercentages,
      required this.questionMode,
      required this.questionType,
      required this.difficultyLevel,
      required this.grammarPoint,
      this.averageTimeSeconds,
      this.lastUpdated,
      final Map<String, dynamic>? metadata})
      : _answerDistribution = answerDistribution,
        _answerPercentages = answerPercentages,
        _metadata = metadata;

  factory _$QuestionAnalyticsImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuestionAnalyticsImplFromJson(json);

  @override
  final String questionId;
  @override
  final int totalAttempts;
  @override
  final int correctAttempts;
  @override
  final int wrongAttempts;
  @override
  final double correctPercentage;
  final Map<String, int> _answerDistribution;
  @override
  Map<String, int> get answerDistribution {
    if (_answerDistribution is EqualUnmodifiableMapView)
      return _answerDistribution;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_answerDistribution);
  }

// {"0": 45, "1": 20, "2": 15, "3": 12}
  final Map<String, double> _answerPercentages;
// {"0": 45, "1": 20, "2": 15, "3": 12}
  @override
  Map<String, double> get answerPercentages {
    if (_answerPercentages is EqualUnmodifiableMapView)
      return _answerPercentages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_answerPercentages);
  }

// {"0": 48.9, "1": 21.7, "2": 16.3, "3": 13.1}
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
  final int? averageTimeSeconds;
  @override
  final DateTime? lastUpdated;
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
    return 'QuestionAnalytics(questionId: $questionId, totalAttempts: $totalAttempts, correctAttempts: $correctAttempts, wrongAttempts: $wrongAttempts, correctPercentage: $correctPercentage, answerDistribution: $answerDistribution, answerPercentages: $answerPercentages, questionMode: $questionMode, questionType: $questionType, difficultyLevel: $difficultyLevel, grammarPoint: $grammarPoint, averageTimeSeconds: $averageTimeSeconds, lastUpdated: $lastUpdated, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestionAnalyticsImpl &&
            (identical(other.questionId, questionId) ||
                other.questionId == questionId) &&
            (identical(other.totalAttempts, totalAttempts) ||
                other.totalAttempts == totalAttempts) &&
            (identical(other.correctAttempts, correctAttempts) ||
                other.correctAttempts == correctAttempts) &&
            (identical(other.wrongAttempts, wrongAttempts) ||
                other.wrongAttempts == wrongAttempts) &&
            (identical(other.correctPercentage, correctPercentage) ||
                other.correctPercentage == correctPercentage) &&
            const DeepCollectionEquality()
                .equals(other._answerDistribution, _answerDistribution) &&
            const DeepCollectionEquality()
                .equals(other._answerPercentages, _answerPercentages) &&
            (identical(other.questionMode, questionMode) ||
                other.questionMode == questionMode) &&
            (identical(other.questionType, questionType) ||
                other.questionType == questionType) &&
            (identical(other.difficultyLevel, difficultyLevel) ||
                other.difficultyLevel == difficultyLevel) &&
            (identical(other.grammarPoint, grammarPoint) ||
                other.grammarPoint == grammarPoint) &&
            (identical(other.averageTimeSeconds, averageTimeSeconds) ||
                other.averageTimeSeconds == averageTimeSeconds) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      questionId,
      totalAttempts,
      correctAttempts,
      wrongAttempts,
      correctPercentage,
      const DeepCollectionEquality().hash(_answerDistribution),
      const DeepCollectionEquality().hash(_answerPercentages),
      questionMode,
      questionType,
      difficultyLevel,
      grammarPoint,
      averageTimeSeconds,
      lastUpdated,
      const DeepCollectionEquality().hash(_metadata));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestionAnalyticsImplCopyWith<_$QuestionAnalyticsImpl> get copyWith =>
      __$$QuestionAnalyticsImplCopyWithImpl<_$QuestionAnalyticsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuestionAnalyticsImplToJson(
      this,
    );
  }
}

abstract class _QuestionAnalytics implements QuestionAnalytics {
  const factory _QuestionAnalytics(
      {required final String questionId,
      required final int totalAttempts,
      required final int correctAttempts,
      required final int wrongAttempts,
      required final double correctPercentage,
      required final Map<String, int> answerDistribution,
      required final Map<String, double> answerPercentages,
      required final String questionMode,
      required final String questionType,
      required final int difficultyLevel,
      required final String grammarPoint,
      final int? averageTimeSeconds,
      final DateTime? lastUpdated,
      final Map<String, dynamic>? metadata}) = _$QuestionAnalyticsImpl;

  factory _QuestionAnalytics.fromJson(Map<String, dynamic> json) =
      _$QuestionAnalyticsImpl.fromJson;

  @override
  String get questionId;
  @override
  int get totalAttempts;
  @override
  int get correctAttempts;
  @override
  int get wrongAttempts;
  @override
  double get correctPercentage;
  @override
  Map<String, int> get answerDistribution;
  @override // {"0": 45, "1": 20, "2": 15, "3": 12}
  Map<String, double> get answerPercentages;
  @override // {"0": 48.9, "1": 21.7, "2": 16.3, "3": 13.1}
  String get questionMode;
  @override // 'practice' or 'exam'
  String get questionType;
  @override // 'grammar' or 'vocabulary'
  int get difficultyLevel;
  @override
  String get grammarPoint;
  @override
  int? get averageTimeSeconds;
  @override
  DateTime? get lastUpdated;
  @override
  Map<String, dynamic>? get metadata;
  @override
  @JsonKey(ignore: true)
  _$$QuestionAnalyticsImplCopyWith<_$QuestionAnalyticsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
