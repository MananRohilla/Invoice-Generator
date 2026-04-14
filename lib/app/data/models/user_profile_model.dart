import 'package:hive/hive.dart';

part 'user_profile_model.g.dart';

@HiveType(typeId: 3)
class UserProfileModel extends HiveObject {
  @HiveField(0)
  String businessName;

  @HiveField(1)
  String address;

  @HiveField(2)
  String email;

  @HiveField(3)
  String phone;

  @HiveField(4)
  String? gstin;

  @HiveField(5)
  String? logoPath;

  @HiveField(6)
  double defaultGstRate;

  @HiveField(7)
  String defaultTerms;

  @HiveField(8)
  String defaultNotes;

  @HiveField(9)
  String? googleDisplayName;

  @HiveField(10)
  String? googlePhotoUrl;

  UserProfileModel({
    required this.businessName,
    this.address = '',
    required this.email,
    this.phone = '',
    this.gstin,
    this.logoPath,
    this.defaultGstRate = 18.0,
    this.defaultTerms = 'Due on Receipt',
    this.defaultNotes = 'Thank you for your business!',
    this.googleDisplayName,
    this.googlePhotoUrl,
  });
}
