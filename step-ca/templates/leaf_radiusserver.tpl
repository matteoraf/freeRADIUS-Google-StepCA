{
	"subject": {
		"country": {{ toJson .country }},
		"organization": {{ toJson .organization }},
		"commonName": {{ toJson .Subject.CommonName }}
    	},
	"sans": {{ toJson .SANs }},
	"keyUsage": ["keyEncipherment", "digitalSignature"],
	"extKeyUsage": ["serverAuth", "clientAuth"],
	"policyIdentifiers" : ["1.3.6.1.4.1.40808.1.3.2"]
}