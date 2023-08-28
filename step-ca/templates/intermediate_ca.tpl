{
	"subject": {{ toJson .Subject }},
	"keyUsage": ["certSign", "crlSign"],
	"basicConstraints": {
		"isCA": true,
		"maxPathLen": 0
	},
    "crlDistributionPoints": ["https://ca.example.com/crl"]
}