import 'dart:async';

import 'package:rxdart/subjects.dart';

abstract class SubjectStreamInterface<T> {
  Stream<T> get stream;
}

// When you want the stream and the value
abstract class BehaviorSubjectStreamInterface<T>
    extends SubjectStreamInterface<T> {
  T get value;
}

abstract class SubjectSinkInterface<T> {
  StreamSink<T> get sink;
}

abstract class SubjectInterface<T>
    implements SubjectStreamInterface<T>, SubjectSinkInterface<T> {}

abstract class BehaviorSubjectInterface<T>
    implements BehaviorSubjectStreamInterface<T>, SubjectSinkInterface<T> {}

/// Default to distinct for the stream
/// To use to dispatch distinct values
class BehaviorSubjectWrapper<T> extends _SubjectWrapper<T>
    implements BehaviorSubjectInterface<T> {
  BehaviorSubjectWrapper({T seedValue})
      : super(BehaviorSubject<T>.seeded(seedValue));

  @override
  T get value => (_subject as BehaviorSubject<T>).value;

  @override
  Stream<T> get stream => _subject.distinct();

  @override
  Future close() {
    return _subject.close();
  }
}

/// To use to dispatch events
class _SubjectWrapper<T> implements SubjectInterface<T> {
  final Subject<T> _subject;

  _SubjectWrapper(this._subject);

  @override
  StreamSink<T> get sink => _subject;

  @override
  Stream<T> get stream => _subject;

  Future close() {
    return _subject.close();
  }
}

/// Default to non distinct
class PublishSubjectWrapper<T> extends _SubjectWrapper<T> {
  PublishSubjectWrapper() : super(PublishSubject<T>());
}
