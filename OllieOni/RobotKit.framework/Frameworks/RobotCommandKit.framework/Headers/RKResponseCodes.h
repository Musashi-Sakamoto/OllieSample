//
// Copyright 2011 Orbotix Inc. All rights reserved.
//


//TODO: update ollie and sphero
typedef NS_ENUM(uint8_t, RKResponseCode){
   RKResponseCodeOK = 0x00,
   RKResponseCodeErrorGeneral = 0x01,
   RKResponseCodeErrorChecksum = 0x02,
   RKResponseCodeErrorFragment = 0x03,
   RKResponseCodeErrorBadCommand = 0x04,
   RKResponseCodeErrorUnsupported = 0x05,
   RKResponseCodeErrorBadMessage = 0x06,
   RKResponseCodeErrorParameter = 0x07,
   RKResponseCodeErrorExecute = 0x08,
   RKResponseCodeUnknownDevice = 0x09,
   RKResponseCodeLowVoltageError = 0x31,
   RKResponseCodeIllegalPageNum = 0x32,
   RKResponseCodeFlashFail = 0x33,
   RKResponseCodeMainAppCorrupt = 0x34,
   RKResponseCodeResponseTimeout = 0x35,
   RKResponseCodeErrorTimeout = 0xFE, // SDK introduced
   RKResponseCodeTimeoutErr = 0xFF
};
