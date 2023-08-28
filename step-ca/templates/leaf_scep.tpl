{
	"subject": {
        "commonName": {{ toJson .Subject.CommonName }},
        "country": {{ toJson .country }},
        "organization": {{ toJson .organization }}
       },
    "emailAddresses": {{ toJson .Insecure.CR.EmailAddresses }},
	"sans": {{ toJson .SANs }},
	"keyUsage": ["keyEncipherment", "digitalSignature"],
	"extKeyUsage": ["clientAuth"]
}