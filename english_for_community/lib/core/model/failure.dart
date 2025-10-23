abstract class Failure{
  final String message;

  Failure({required this.message});
}
class AuthFailure extends Failure {
  AuthFailure({required super.message});
}
class UserFailure extends Failure {
  UserFailure({required super.message});
}
class MeetFailure extends Failure {
  MeetFailure({required super.message});
}
class MeetsFailure extends Failure{
  MeetsFailure({required super.message});
}
class ChatFailure extends Failure{
  ChatFailure({required super.message});
}
class ListeningFailure extends Failure{
  ListeningFailure({required super.message});
}
class CueFailure extends Failure{
  CueFailure({required super.message});
}
class JobTypeFailure extends Failure{
  JobTypeFailure({required super.message});
}
class WritingFailure extends Failure{
  WritingFailure({required super.message});
}