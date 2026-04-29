enum UserRole { admin, user }

UserRole parseRole(String? raw) =>
    raw == 'admin' ? UserRole.admin : UserRole.user;

class AppUser {
  const AppUser({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    this.phone,
    this.alternatePhone,
    this.status,
    this.occupation,
    this.income,
    this.currentAddress,
    this.permanentAddress,
    this.aadhaarNumber,
    this.profilePhotoUrl,
  });

  final String id;
  final UserRole role;
  final String name;
  final String email;
  final String? phone;
  final String? alternatePhone;
  final String? status;
  final String? occupation;
  final num? income;
  final String? currentAddress;
  final String? permanentAddress;
  final String? aadhaarNumber;
  final String? profilePhotoUrl;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>?;
    return AppUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      role: parseRole(json['role']?.toString()),
      name: (json['fullName'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: json['phone']?.toString(),
      alternatePhone: json['alternatePhone']?.toString(),
      status: json['status']?.toString(),
      occupation: json['occupation']?.toString(),
      income: json['income'] as num?,
      currentAddress: address?['current']?.toString(),
      permanentAddress: address?['permanent']?.toString(),
      aadhaarNumber: json['aadhaarNumber']?.toString(),
      profilePhotoUrl: json['profilePhotoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'fullName': name,
    'email': email,
    'phone': phone,
    'alternatePhone': alternatePhone,
    'status': status,
    'occupation': occupation,
    'income': income,
    'address': {'current': currentAddress, 'permanent': permanentAddress},
    'aadhaarNumber': aadhaarNumber,
    'profilePhotoUrl': profilePhotoUrl,
  };
}

class AppSession {
  const AppSession({required this.token, required this.user});

  final String token;
  final AppUser user;

  factory AppSession.fromJson(Map<String, dynamic> json) => AppSession(
    token: (json['token'] ?? '').toString(),
    user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {'token': token, 'user': user.toJson()};
}

class PropertyItem {
  const PropertyItem({
    required this.id,
    required this.title,
    required this.type,
    required this.rent,
    required this.deposit,
    required this.description,
    required this.status,
    required this.addressLine,
    required this.city,
    required this.images,
    required this.amenities,
    this.area,
    this.floorSize,
    this.bedrooms,
    this.bathrooms,
    this.shopSize,
    this.businessSuitability,
    this.availableFrom,
    this.featured = false,
    this.tenant,
    this.ownerContactPhone,
    this.ownerContactEmail,
  });

  final String id;
  final String title;
  final String type;
  final num rent;
  final num deposit;
  final String description;
  final String status;
  final String addressLine;
  final String city;
  final List<String> images;
  final List<String> amenities;
  final String? area;
  final String? floorSize;
  final int? bedrooms;
  final int? bathrooms;
  final String? shopSize;
  final String? businessSuitability;
  final String? availableFrom;
  final bool featured;
  final AppUser? tenant;
  final String? ownerContactPhone;
  final String? ownerContactEmail;

  factory PropertyItem.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};
    final images = (json['images'] as List<dynamic>? ?? [])
        .map(
          (item) => item is Map<String, dynamic>
              ? item['url']?.toString() ?? ''
              : item.toString(),
        )
        .where((value) => value.isNotEmpty)
        .toList();
    return PropertyItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      rent: json['rent'] as num? ?? 0,
      deposit: json['deposit'] as num? ?? 0,
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      addressLine: (address['line1'] ?? '').toString(),
      city: (address['city'] ?? '').toString(),
      area: address['area']?.toString(),
      images: images,
      amenities: (json['amenities'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      floorSize: json['floorSize']?.toString(),
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      shopSize: json['shopSize']?.toString(),
      businessSuitability: json['businessSuitability']?.toString(),
      availableFrom: json['availableFrom']?.toString(),
      featured: json['featured'] as bool? ?? false,
      tenant: json['tenantId'] is Map<String, dynamic>
          ? AppUser.fromJson(json['tenantId'] as Map<String, dynamic>)
          : null,
      ownerContactPhone: json['ownerContactPhone']?.toString(),
      ownerContactEmail: json['ownerContactEmail']?.toString(),
    );
  }

  Map<String, dynamic> toCreatePayload() => {
    'title': title,
    'type': type,
    'category': 'rent',
    'address': {'line1': addressLine, 'city': city, 'area': area},
    'rent': rent,
    'deposit': deposit,
    'description': description,
    'images': images.map((url) => {'url': url}).toList(),
    'amenities': amenities,
    'status': status,
    'floorSize': floorSize,
    'bedrooms': bedrooms,
    'bathrooms': bathrooms,
    'shopSize': shopSize,
    'businessSuitability': businessSuitability,
    'availableFrom': availableFrom,
    'featured': featured,
    'ownerContactPhone': ownerContactPhone,
    'ownerContactEmail': ownerContactEmail,
  };
}

class ApplicationPersonalDetails {
  const ApplicationPersonalDetails({
    this.fullName,
    this.fatherName,
    this.mobileNumber,
    this.alternateMobileNumber,
    this.email,
    this.currentAddress,
    this.permanentAddress,
    this.aadhaarNumber,
    this.occupation,
    this.monthlyIncome,
    this.familyMembersCount,
    this.businessType,
    this.requiredRentalStartDate,
  });

  final String? fullName;
  final String? fatherName;
  final String? mobileNumber;
  final String? alternateMobileNumber;
  final String? email;
  final String? currentAddress;
  final String? permanentAddress;
  final String? aadhaarNumber;
  final String? occupation;
  final num? monthlyIncome;
  final int? familyMembersCount;
  final String? businessType;
  final String? requiredRentalStartDate;

  factory ApplicationPersonalDetails.fromJson(Map<String, dynamic> json) =>
      ApplicationPersonalDetails(
        fullName: json['fullName']?.toString(),
        fatherName: json['fatherName']?.toString(),
        mobileNumber: json['mobileNumber']?.toString(),
        alternateMobileNumber: json['alternateMobileNumber']?.toString(),
        email: json['email']?.toString(),
        currentAddress: json['currentAddress']?.toString(),
        permanentAddress: json['permanentAddress']?.toString(),
        aadhaarNumber: json['aadhaarNumber']?.toString(),
        occupation: json['occupation']?.toString(),
        monthlyIncome: json['monthlyIncome'] as num?,
        familyMembersCount: (json['familyMembersCount'] as num?)?.toInt(),
        businessType: json['businessType']?.toString(),
        requiredRentalStartDate: json['requiredRentalStartDate']?.toString(),
      );
}

class ApplicationDocument {
  const ApplicationDocument({
    required this.id,
    required this.label,
    required this.url,
    this.mimeType,
    this.size,
    this.verificationStatus,
    this.notes,
  });

  final String id;
  final String label;
  final String url;
  final String? mimeType;
  final num? size;
  final String? verificationStatus;
  final String? notes;

  factory ApplicationDocument.fromJson(Map<String, dynamic> json) =>
      ApplicationDocument(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        label: (json['label'] ?? 'Document').toString(),
        url: (json['url'] ?? '').toString(),
        mimeType: json['mimeType']?.toString(),
        size: json['size'] as num?,
        verificationStatus: json['verificationStatus']?.toString(),
        notes: json['notes']?.toString(),
      );
}

class RentalApplicationItem {
  const RentalApplicationItem({
    required this.id,
    required this.status,
    required this.applicationDate,
    required this.property,
    this.personalDetails,
    this.documents = const [],
    this.user,
    this.remarks,
    this.adminRemarks,
  });

  final String id;
  final String status;
  final String applicationDate;
  final PropertyItem property;
  final ApplicationPersonalDetails? personalDetails;
  final List<ApplicationDocument> documents;
  final AppUser? user;
  final String? remarks;
  final String? adminRemarks;

  factory RentalApplicationItem.fromJson(Map<String, dynamic> json) =>
      RentalApplicationItem(
        id: (json['_id'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        applicationDate: (json['applicationDate'] ?? json['createdAt'] ?? '')
            .toString(),
        property: PropertyItem.fromJson(
          json['propertyId'] as Map<String, dynamic>,
        ),
        personalDetails: json['personalDetails'] is Map<String, dynamic>
            ? ApplicationPersonalDetails.fromJson(
                json['personalDetails'] as Map<String, dynamic>,
              )
            : null,
        documents: (json['documents'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ApplicationDocument.fromJson)
            .toList(),
        user: json['userId'] is Map<String, dynamic>
            ? AppUser.fromJson(json['userId'] as Map<String, dynamic>)
            : null,
        remarks: json['remarks']?.toString(),
        adminRemarks: json['adminRemarks']?.toString(),
      );
}

class PaymentItem {
  const PaymentItem({
    required this.id,
    required this.amount,
    required this.month,
    required this.status,
    required this.property,
    this.receiptUrl,
    this.paidDate,
    this.transactionId,
  });

  final String id;
  final num amount;
  final String month;
  final String status;
  final PropertyItem property;
  final String? receiptUrl;
  final String? paidDate;
  final String? transactionId;

  factory PaymentItem.fromJson(Map<String, dynamic> json) => PaymentItem(
    id: (json['_id'] ?? '').toString(),
    amount: json['amount'] as num? ?? 0,
    month: (json['month'] ?? '').toString(),
    status: (json['status'] ?? '').toString(),
    property: PropertyItem.fromJson(json['propertyId'] as Map<String, dynamic>),
    receiptUrl: json['receiptUrl']?.toString(),
    paidDate: json['paidDate']?.toString(),
    transactionId: json['transactionId']?.toString(),
  );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.message,
    required this.senderId,
    required this.senderModel,
    required this.createdAt,
  });

  final String id;
  final String message;
  final String senderId;
  final String senderModel;
  final String createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: (json['_id'] ?? '').toString(),
    message: (json['message'] ?? '').toString(),
    senderId: (json['senderId'] ?? '').toString(),
    senderModel: (json['senderModel'] ?? '').toString(),
    createdAt: (json['createdAt'] ?? '').toString(),
  );
}

class ChatThread {
  const ChatThread({
    required this.participantId,
    required this.participantModel,
    required this.lastMessage,
  });

  final String participantId;
  final String participantModel;
  final ChatMessage lastMessage;

  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
    participantId: (json['participantId'] ?? '').toString(),
    participantModel: (json['participantModel'] ?? '').toString(),
    lastMessage: ChatMessage.fromJson(
      json['lastMessage'] as Map<String, dynamic>,
    ),
  );
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final String createdAt;
  final bool isRead;

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: (json['_id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        body: (json['body'] ?? '').toString(),
        type: (json['type'] ?? '').toString(),
        createdAt: (json['createdAt'] ?? '').toString(),
        isRead: json['isRead'] as bool? ?? false,
      );
}

class ComplaintItem {
  const ComplaintItem({
    required this.id,
    required this.subject,
    required this.description,
    required this.status,
    required this.propertyTitle,
    this.adminReply,
  });

  final String id;
  final String subject;
  final String description;
  final String status;
  final String propertyTitle;
  final String? adminReply;

  factory ComplaintItem.fromJson(Map<String, dynamic> json) => ComplaintItem(
    id: (json['_id'] ?? '').toString(),
    subject: (json['subject'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    status: (json['status'] ?? '').toString(),
    propertyTitle:
        (json['propertyId'] is Map<String, dynamic>
                ? json['propertyId']['title']
                : 'Property')
            .toString(),
    adminReply: json['adminReply']?.toString(),
  );
}

class AgreementItem {
  const AgreementItem({
    required this.id,
    required this.title,
    required this.propertyTitle,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.fileUrl,
  });

  final String id;
  final String title;
  final String propertyTitle;
  final String startDate;
  final String endDate;
  final String status;
  final String? fileUrl;

  factory AgreementItem.fromJson(Map<String, dynamic> json) => AgreementItem(
    id: (json['_id'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    propertyTitle:
        (json['propertyId'] is Map<String, dynamic>
                ? json['propertyId']['title']
                : 'Property')
            .toString(),
    startDate: (json['startDate'] ?? '').toString(),
    endDate: (json['endDate'] ?? '').toString(),
    status: (json['status'] ?? '').toString(),
    fileUrl: json['agreementFileUrl']?.toString(),
  );
}

class DashboardSummary {
  const DashboardSummary({
    required this.totalProperties,
    required this.availableProperties,
    required this.occupiedProperties,
    required this.pendingApplications,
    required this.approvedTenants,
    required this.monthlyRentCollection,
    required this.duePayments,
    required this.totalComplaints,
  });

  final int totalProperties;
  final int availableProperties;
  final int occupiedProperties;
  final int pendingApplications;
  final int approvedTenants;
  final num monthlyRentCollection;
  final int duePayments;
  final int totalComplaints;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        totalProperties: json['totalProperties'] as int? ?? 0,
        availableProperties: json['availableProperties'] as int? ?? 0,
        occupiedProperties: json['occupiedProperties'] as int? ?? 0,
        pendingApplications: json['pendingApplications'] as int? ?? 0,
        approvedTenants: json['approvedTenants'] as int? ?? 0,
        monthlyRentCollection: json['monthlyRentCollection'] as num? ?? 0,
        duePayments: json['duePayments'] as int? ?? 0,
        totalComplaints: json['totalComplaints'] as int? ?? 0,
      );
}

class OtpRoutePayload {
  const OtpRoutePayload({
    required this.email,
    required this.accountType,
    this.devOtp,
  });

  final String email;
  final String accountType;
  final String? devOtp;
}

class ResetPasswordPayload {
  const ResetPasswordPayload({
    required this.email,
    required this.accountType,
    this.devOtp,
  });

  final String email;
  final String accountType;
  final String? devOtp;
}
