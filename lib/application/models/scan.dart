class ScanSubmit
{
  final String imei;
  final String qrCode;
  final String lattitude;
  final String longitude;
  final String type;

  ScanSubmit({this.imei,this.qrCode,this.lattitude,this.longitude,this.type});

  factory ScanSubmit.fromJson(Map<String, dynamic> json)
  {
    return ScanSubmit
      (
        imei       :   json['imei'],
        qrCode     :   json['qrCode'],
        lattitude  :   json['lattitude'],
        longitude  :   json['longitude'],
        type       :   json['type']
    );
  }

  Map toMap()
  {
    var map = new Map<String, dynamic>();
    map["imei"]       = imei;
    map["qrCode"]     = qrCode;
    map["lattitude"]  = lattitude;
    map["longitude"]  = longitude;
    map["type"]       = type; 
    return map;
  } 
}


class ScanReturn
{
  final int apiReturn;
  final String apiMessage;

  ScanReturn({this.apiReturn,this.apiMessage});

  factory ScanReturn.fromJson(Map<String, dynamic> json)
  {
    return ScanReturn
      (
        apiReturn    : json['apiReturn'],
        apiMessage   : json['apiMessage'] 
    );
  }

  Map toMap()
  {
    var map = new Map<String, dynamic>();
    map["apiReturn"]    = apiReturn;
    map["apiMessage"]    = apiMessage; 
    return map;
  } 
}