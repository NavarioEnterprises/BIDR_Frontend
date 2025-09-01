-- SQL script to add missing flag fields to the product_request table
-- Run this script on your product management service database

-- Add is_flagged column
ALTER TABLE product_request 
ADD COLUMN is_flagged BOOLEAN DEFAULT FALSE;

-- Add comment to the is_flagged column
COMMENT ON COLUMN product_request.is_flagged IS 'Whether this request has been flagged by sellers';

-- Add flags column (JSON field)
ALTER TABLE product_request 
ADD COLUMN flags TEXT DEFAULT '[]';

-- Add comment to the flags column  
COMMENT ON COLUMN product_request.flags IS 'List of flags with uid, reason, and timestamp (JSON array)';

-- Update any existing NULL values to proper defaults
UPDATE product_request 
SET is_flagged = FALSE 
WHERE is_flagged IS NULL;

UPDATE product_request 
SET flags = '[]' 
WHERE flags IS NULL OR flags = '';

-- Make sure the columns are not nullable
ALTER TABLE product_request 
ALTER COLUMN is_flagged SET NOT NULL;

ALTER TABLE product_request 
ALTER COLUMN flags SET NOT NULL;