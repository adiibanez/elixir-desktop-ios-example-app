xcrun simctl list devices

iPhone 16 Pro (B7F7F923-C652-4F96-A5AF-10E21D81A69D) (Shutdown)
iPhone 16 Pro Max (818CA012-33C6-40F6-B055-9D9792E8BE18) (Shutdown)
iPhone 16 (7FDD9E8B-ADF7-4789-BEF3-6EE7E3451034) (Shutdown)
iPhone 16 Plus (307C604B-D0B2-41C5-80C7-A22DDA479DE8) (Shutdown)
iPhone SE (3rd generation) (30A90073-9EE6-4829-8C16-5EB92BF0B4D4) (Booted)
iPad Pro 11-inch (M4) (4C844D23-A3CE-4E6E-B4EC-F4857FF54DF1) (Shutdown)
iPad Pro 13-inch (M4) (770D39CD-F134-4085-82D5-9EEDB669994C) (Shutdown)
iPad Air 11-inch (M2) (F341CDD7-2F94-4B15-B94F-3DF9D1A914C5) (Shutdown)
iPad Air 13-inch (M2) (C103F3CA-C890-467D-A9CE-92DCE2EFE92F) (Shutdown)
iPad mini (A17 Pro) (347D6FBB-0F39-40D0-B4D8-3BEC1AF75C57) (Shutdown)
iPad (10th generation) (B4FDFA07-FD5F-49DE-8643-4C6DD0E0553B) (Booted)
  
xcrun simctl boot 30A90073-9EE6-4829-8C16-5EB92BF0B4D4

# xcrun simctl openurl booted "x-apple-simulator://?deviceSetPath=/Users/$USER/Library/Developer/CoreSimulator/Devices/<device_UUID>"