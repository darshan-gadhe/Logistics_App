enum PaymentStatus { pending, paid }
enum PaymentMethod { notSet, cash, card, online }

class PaymentTransaction {
  final String id;
  final String associatedName;
  final String description;
  final double amount;
  final PaymentStatus status;
  final PaymentMethod method;
  final DateTime date;

  const PaymentTransaction({
    required this.id,
    required this.associatedName,
    required this.description,
    required this.amount,
    required this.status,
    required this.method,
    required this.date,
  });
}