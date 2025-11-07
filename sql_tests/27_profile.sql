-- Create Profile and user myuser
drop user if exists myuser;
drop profile  if exists myprofile;
CREATE PROFILE myprofile;
CREATE USER myuser PASSWORD 'mypassword';
-- Bind Profile to user myuser
ALTER USER myuser PROFILE myprofile;
-- View relationship between user myuser and Profile
SELECT rolname, rolprofile FROM pg_roles WHERE rolname = 'myuser'; 

-- Set maximum failed login attempts to 3 and password lock time to 2 hours
ALTER PROFILE myprofile LIMIT  FAILED_LOGIN_ATTEMPTS 3  PASSWORD_LOCK_TIME 2;
-- Enable Profile for user myuser
ALTER USER myuser ENABLE PROFILE;
-- View password policy details
SELECT prfname, prffailedloginattempts, prfpasswordlocktime FROM pg_profile WHERE prfname = 'myprofile';

-- View user status
SELECT rolname, rolprofile, get_role_status('myuser'), rolfailedlogins, rollockdate FROM pg_roles WHERE rolname = 'myuser';