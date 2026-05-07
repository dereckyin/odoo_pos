from .base import InvoiceDriver
from .ecpay_invoice import EcpayInvoiceDriver
from .ezpay import EzpayInvoiceDriver


def invoice_driver_for(name: str) -> InvoiceDriver:
    if name == "ezpay":
        return EzpayInvoiceDriver()
    if name == "ecpay" or name == "ecpay_invoice":
        return EcpayInvoiceDriver()
    raise ValueError(f"unknown invoice driver: {name}")
