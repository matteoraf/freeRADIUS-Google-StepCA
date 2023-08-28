{
	"subject": {
        "country": {{ toJson .Insecure.User.country }},
        "organization": {{ toJson .Insecure.User.organization }},
        "commonName": {{ toJson .Subject.CommonName }}
        },
	"keyUsage": ["certSign", "crlSign", "digitalSignature", "keyEncipherment"],
	"basicConstraints": {
		"isCA": true,
		"maxPathLen": 0
	},
    "crlDistributionPoints": ["http://ca.example.com/crl"]
}