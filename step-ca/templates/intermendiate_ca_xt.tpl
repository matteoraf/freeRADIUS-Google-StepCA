{
	"subject": {
	    "country": {{ toJson .Insecure.User.country }},
	    "organization": {{ toJson .Insecure.User.organization }},
	    "commonName": {{ toJson .Subject.CommonName }}
        },
	"keyUsage": ["certSign", "crlSign"],
	"basicConstraints": {
		"isCA": true,
		"maxPathLen": 0
	},
    "crlDistributionPoints": ["https://ca.example.com/crl"]
}