/**
 * 最小 WebUSB API 型別宣告。
 *
 * TypeScript 標準 lib 不含 WebUSB（需要 @types/w3c-web-usb 或類似套件），
 * 這裡只宣告本專案實際用到的子集，避免額外相依套件與 npm install 的不確定性。
 * 對應 Chrome/Edge 的 WebUSB 規格：https://wicg.github.io/webusb/
 */

interface USBEndpoint {
  endpointNumber: number
  direction: 'in' | 'out'
  type: 'bulk' | 'interrupt' | 'isochronous'
}

interface USBAlternateInterface {
  alternateSetting: number
  interfaceClass: number
  interfaceSubclass: number
  interfaceProtocol: number
  interfaceName: string | null
  endpoints: USBEndpoint[]
}

interface USBInterface {
  interfaceNumber: number
  alternate: USBAlternateInterface
  alternates: USBAlternateInterface[]
  claimed: boolean
}

interface USBConfiguration {
  configurationValue: number
  configurationName: string | null
  interfaces: USBInterface[]
}

interface USBOutTransferResult {
  bytesWritten: number
  status: 'ok' | 'stall' | 'babble'
}

interface USBInTransferResult {
  data?: DataView
  status: 'ok' | 'stall' | 'babble'
}

interface USBDevice {
  readonly vendorId: number
  readonly productId: number
  readonly manufacturerName?: string
  readonly productName?: string
  readonly serialNumber?: string
  readonly opened: boolean
  readonly configuration: USBConfiguration | null
  readonly configurations: USBConfiguration[]
  open(): Promise<void>
  close(): Promise<void>
  selectConfiguration(configurationValue: number): Promise<void>
  claimInterface(interfaceNumber: number): Promise<void>
  releaseInterface(interfaceNumber: number): Promise<void>
  transferOut(endpointNumber: number, data: BufferSource): Promise<USBOutTransferResult>
  transferIn(endpointNumber: number, length: number): Promise<USBInTransferResult>
}

interface USBDeviceFilter {
  vendorId?: number
  productId?: number
  classCode?: number
  subclassCode?: number
  protocolCode?: number
  serialNumber?: string
}

interface USBDeviceRequestOptions {
  filters: USBDeviceFilter[]
}

interface USBConnectionEvent extends Event {
  readonly device: USBDevice
}

interface USB extends EventTarget {
  getDevices(): Promise<USBDevice[]>
  requestDevice(options: USBDeviceRequestOptions): Promise<USBDevice>
  addEventListener(
    type: 'connect' | 'disconnect',
    listener: (this: USB, ev: USBConnectionEvent) => void,
  ): void
  removeEventListener(
    type: 'connect' | 'disconnect',
    listener: (this: USB, ev: USBConnectionEvent) => void,
  ): void
}

interface Navigator {
  readonly usb?: USB
}
