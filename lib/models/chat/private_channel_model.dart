class PrivateChannelModel {
  final String channelId;

  const PrivateChannelModel({required this.channelId});

  factory PrivateChannelModel.fromJson(Map<String, dynamic> json) {
    return PrivateChannelModel(channelId: json['channelId'] as String);
  }
}