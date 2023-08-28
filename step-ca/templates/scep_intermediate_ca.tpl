{
	"subject": {{ toJson .Subject }},
	"keyUsage": ["certSign", "crlSign", "digitalSignature", "keyEncipherment"],
	"basicConstraints": {
		"isCA": true,
		"maxPathLen": 0
	},
    "crlDistributionPoints": ["http://ca.example.com/crl"]
}