import 'dart:io';


abstract class UserEvent{

}
class LoginEvent extends UserEvent{
  final String email;
  final String password;

  LoginEvent({required this.email, required this.password});
}
class GetUserEvent extends UserEvent{

}
class SignOutEvent extends UserEvent{

}