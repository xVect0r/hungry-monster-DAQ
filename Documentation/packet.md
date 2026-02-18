#### Data Packet format

- 4 bytes -> Header
- 4 bytes -> Timestamp
- 1 bytes -> Channel_ID
- 1 bytes -> Sample Count
- Nx (4 bytes) -> Data Payload
- 4 bytes -> Error Flags
- 1 bytes -> End Marker

tlast is asserted in the end