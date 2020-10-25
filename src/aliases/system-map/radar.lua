-- Intercept the radar command to enable our radar scraping triggers.
-- We don't want them to potentially fire on unrelated lines.
enableTrigger("system-map-radar")
send("radar", false)
