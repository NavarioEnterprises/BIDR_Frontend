class OTPGenerator:
    """
    Utility class for generating and validating OTPs
    """

    @staticmethod
    def generate_otp(length=6):
        """
        Generate a random OTP of specified length
        """
        return ''.join(random.choices(string.digits, k=length))

    @staticmethod
    def generate_secure_otp(user_id, timestamp=None):
        """
        Generate a secure OTP based on user ID and timestamp
        """
        if timestamp is None:
            timestamp = timezone.now()

        # Create a seed based on user ID and timestamp
        seed = f"{user_id}:{timestamp.isoformat()}:{settings.SECRET_KEY}"

        # Generate hash
        hash_object = hashlib.sha256(seed.encode())
        hash_hex = hash_object.hexdigest()

        # Extract 6 digits from hash
        otp = ''.join(filter(str.isdigit, hash_hex))[:6]

        # Ensure we have 6 digits
        while len(otp) < 6:
            otp += str(random.randint(0, 9))

        return otp[:6]

    @staticmethod
    def validate_otp_format(otp):
        """
        Validate OTP format
        """
        return otp.isdigit() and len(otp) == 6

