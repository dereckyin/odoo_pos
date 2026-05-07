from .base import PaymentDriver
from .ecpay import EcpayDriver
from .linepay import LinePayDriver
from .newebpay import NewebPayDriver


def registered_drivers() -> dict[str, PaymentDriver]:
    return {
        "linepay": LinePayDriver(),
        "newebpay": NewebPayDriver(),
        "ecpay": EcpayDriver(),
    }


def driver_for(name: str) -> PaymentDriver:
    drivers = registered_drivers()
    if name not in drivers:
        raise ValueError(f"unknown payment driver: {name}")
    return drivers[name]
