from allyin_licensing.license_manager import LicenseManager
fixed_secret = b'mOB5buxbCRj5BDIw6FmBGId04p5AiyMGB60pZ55sE_A='
lm = LicenseManager(product_id="SiliGenius")
lm.secret_key = fixed_secret
key, data = lm.generate_license_key(
    customer_id="Niraj@AllyInAi.onmicrosoft.com",
    days=7,
    license_type="paid",
    sigtype="hmac"
)

print(f"License Key: {key}")
print(f"License Data: {data}")