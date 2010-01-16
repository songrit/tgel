var CAPICOM_STORE_OPEN_READ_ONLY = 0;
var CAPICOM_LOCAL_MACHINE_STORE = 1;
var CAPICOM_CURRENT_USER_STORE = 2;   
var CAPICOM_CERTIFICATE_FIND_SHA1_HASH = 0;   
var CAPICOM_CERTIFICATE_FIND_SUBJECT_NAME = 1;
var CAPICOM_CERTIFICATE_FIND_EXTENDED_PROPERTY = 6;   
var CAPICOM_CERTIFICATE_FIND_TIME_VALID = 9;   
var CAPICOM_CERTIFICATE_FIND_KEY_USAGE = 12;   
var CAPICOM_DIGITAL_SIGNATURE_KEY_USAGE = 0x00000080;   
var CAPICOM_AUTHENTICATED_ATTRIBUTE_SIGNING_TIME = 0;   
var CAPICOM_INFO_SUBJECT_SIMPLE_NAME = 0;   
var CAPICOM_ENCODE_BASE64 = 0;   
var CAPICOM_E_CANCELLED = -2138568446;   
var CERT_KEY_SPEC_PROP_ID = 6;   
var CAPICOM_CERT_INFO_SUBJECT_SIMPLE_NAME = 0;
var CAPICOM_CERT_INFO_ISSUER_SIMPLE_NAME = 1; 
var CAPICOM_VERIFY_SIGNATURE_ONLY = 0;
var CAPICOM_VERIFY_SIGNATURE_AND_CERTIFICATE = 1;
var CAPICOM_ENCODE_BASE64 = 0;   

function signDigital(userName, plainText, imgSign){
	try{
		var MyStore = new ActiveXObject("CAPICOM.Store");   
		MyStore.Open(CAPICOM_CURRENT_USER_STORE, "My", CAPICOM_STORE_OPEN_READ_ONLY);
		var FilteredCertificates = MyStore.Certificates.Find(CAPICOM_CERTIFICATE_FIND_SUBJECT_NAME, userName);   
		var signer = new ActiveXObject("CAPICOM.Signer"); 
		signer.Certificate = FilteredCertificates.Item(1);   
		var certificate = new ActiveXObject("CAPICOM.Certificate"); 
		certificate = signer.Certificate
		//alert(certificate.GetInfo(CAPICOM_CERT_INFO_SUBJECT_SIMPLE_NAME) );
		//alert(certificate.GetInfo(CAPICOM_CERT_INFO_ISSUER_SIMPLE_NAME));
		var signedData = new ActiveXObject("CAPICOM.SignedData"); 
		signedData.Content = plainText; 
		var signedDataText= signedData.Sign(signer,true,CAPICOM_ENCODE_BASE64); 
                //alert("ท่านได้ทำการลงลายมือชื่อดิจิตอลเป็นที่เรียบร้อยแล้ว\nCertificate : "+certificate.GetInfo(CAPICOM_CERT_INFO_SUBJECT_SIMPLE_NAME)+"\nIssuer : "+certificate.GetInfo(CAPICOM_CERT_INFO_ISSUER_SIMPLE_NAME));
                imgSign.src = "/images/valid.jpg";
		return signedDataText; 
	}catch(e){
		alert("เกิดความผิดพลาด : "+e.description);
		return "";
	}
}

function verifySignature(plainText, signedMessage, imgVerify){
	try{
		var certificate = new ActiveXObject("CAPICOM.Certificate"); 
		var signedData = new ActiveXObject("CAPICOM.SignedData"); 
		signedData.Content = plainText; 
		var verifyMessage = signedData.Verify(signedMessage, true, CAPICOM_VERIFY_SIGNATURE_ONLY);
		certificate=signedData.Certificates(1);
		//alert(certificate.GetInfo(CAPICOM_CERT_INFO_SUBJECT_SIMPLE_NAME) );
		//alert(certificate.GetInfo(CAPICOM_CERT_INFO_ISSUER_SIMPLE_NAME));
		alert(verifyMessage);
                imgVerify.src = "/images/valid.jpg";
		return true;
	}catch(e){
		alert("เกิดความผิดพลาด : "+e.description);
                imgVerify.src = "/images/invalid.jpg";
		return false;
	}
}

function verifySignature2(plainText, signedMessage){
	try{
		var certificate = new ActiveXObject("CAPICOM.Certificate");
		var signedData = new ActiveXObject("CAPICOM.SignedData");
		signedData.Content = plainText;
		var verifyMessage = signedData.Verify(signedMessage, true, CAPICOM_VERIFY_SIGNATURE_ONLY);
		certificate=signedData.Certificates(1);
		//alert(certificate.GetInfo(CAPICOM_CERT_INFO_SUBJECT_SIMPLE_NAME) );
		//alert(certificate.GetInfo(CAPICOM_CERT_INFO_ISSUER_SIMPLE_NAME));
		//alert(verifyMessage);
		return true;
	}catch(e){
		//alert("เกิดความผิดพลาด : "+e.description);
		return false;
	}
}