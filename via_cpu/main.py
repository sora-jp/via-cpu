import sys
import hid
import asyncio
import psutil

vendor_id     = 0x04d8
product_id    = 0xeb2d

usage_page    = 0xFF60
usage         = 0x61
report_length = 32

def get_raw_hid_interface():
    device_interfaces = hid.enumerate(vendor_id, product_id)
    raw_hid_interfaces = [i for i in device_interfaces if i['usage_page'] == usage_page and i['usage'] == usage]

    if len(raw_hid_interfaces) == 0:
        return None

    interface = hid.Device(path=raw_hid_interfaces[0]['path'])

    return interface

def send_raw_report(data):
    interface = get_raw_hid_interface()

    if interface is None:
        print("No device found")
        sys.exit(1)

    request_data = [0x00] * (report_length + 1) # First byte is Report ID
    request_data[1:len(data) + 1] = data
    request_report = bytes(request_data)

    try:
        interface.write(request_report)
        response_report = interface.read(report_length, timeout=1000)
    finally:
        interface.close()

async def _main():
    while True:
        await asyncio.sleep(1)
        cpu = int(psutil.cpu_percent())
        mem = int(psutil.virtual_memory().percent)
        try:
            send_raw_report([
                0x07, cpu, mem
            ])
        except:
            pass

def main():
    asyncio.run(_main())
