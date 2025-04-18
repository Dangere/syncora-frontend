import 'package:email_validator/email_validator.dart';

class Validators {
  static bool validateEmail(String email) {
    return EmailValidator.validate(email);
  }

  static bool validatePassword(String password) {
    //password must be between 6 and 16 characters
    if (password.length > 32 || password.length < 6) return false;

    return true;
  }

  // static bool ValidateName(String name)
  // {
  //     if (!(name.length <= 10 && name.length >= 2))
  //         return false;

  //     String[] namesArray = name.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries);
  //     if (namesArray.length != 1)
  //     {
  //         return false;
  //     }

  //     Regex regex = new(@"[A-Za-z., '-]+");
  //     Match match = regex.Match(name);

  //     return match.Success;
  // }

  // static bool ValidatePhone(String phone)
  // { //phone must be between 10 and 16 characters
  //     if (phone.length > 16 || phone.length < 10)
  //         return false;

  //     Regex regex = new(@"\(?\d{3}\)?-? *\d{3}-? *-?\d{4}");
  //     Match match = regex.Match(phone);
  //     return match.Success;
  // }
}
