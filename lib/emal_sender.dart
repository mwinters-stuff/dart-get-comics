import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailSender {
  String smtp_server;
  int smtp_port;
  String smtp_username;
  String smtp_password;
  String sender;

  late SmtpServer _smtpServer;

  late PersistentConnection _connection;

  EmailSender(this.smtp_server, this.smtp_port, this.smtp_username,
      this.smtp_password, this.sender) {
    this._smtpServer = SmtpServer(smtp_server,
        port: smtp_port, username: smtp_username, password: smtp_password);
    this._connection = PersistentConnection(_smtpServer);
  }

  Future<bool> send(List<String> to, String subject, String imageUrl) async {
    final message = Message()
      ..from = Address(sender, "Comics Mailer")
      ..recipients.addAll(to)
      ..subject = subject
      ..html = "<H1>$subject</H1><BR><img src='$imageUrl'>";

    try {
      SendReport sendReport = await _connection.send(message);
      print('Message sent: $sendReport');
      return true;
    } on MailerException catch (e) {
      print('Message not sent. $e');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      return false;
    }
  }

  void disconnect() {
    _connection
        .close()
        .then((value) => print("Done"))
        .onError((error, stackTrace) => print("Close Error: $error"));
  }
}
