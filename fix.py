import json
from decimal import Decimal, getcontext
from typing import Dict, Union, Any

getcontext().prec = 50

class TomoRewardEconomy:
    def __init__(self, initial: Union[int, float, Decimal] = 0):
        self._balance: Decimal = Decimal(str(initial))
        self._multipliers: Dict[str, Decimal] = {}
        self._base_multiplier: Decimal = Decimal('1')

    def set_rate(self, identifier: str, rate: Union[int, float]) -> None:
        self._multipliers[identifier] = Decimal(str(rate))

    def _get_multiplier(self, identifier: str = 'default') -> Decimal:
        return self._multipliers.get(identifier, self._base_multiplier)

    def accrue(self, amount: Union[int, float], identifier: str = 'default') -> Decimal:
        raw = Decimal(str(amount))
        rate = self._get_multiplier(identifier)
        self._balance = self._balance + (raw * rate)
        return self._balance

    def get_value(self, identifier: str = 'default') -> Decimal:
        return self._balance * self._get_multiplier(identifier)

    def serialize(self) -> str:
        return json.dumps({
            'balance': str(self._balance),
            'multipliers': {k: str(v) for k, v in self._multipliers.items()}
        })

    @classmethod
    def from_json(cls, data: Dict[str, Any]) -> 'TomoRewardEconomy':
        instance = cls()
        instance._balance = Decimal(str(data.get('balance', 0)))
        for k, v in data.get('multipliers', {}).items():
            instance._multipliers[k] = Decimal(str(v))
        return instance

    def __str__(self) -> str:
        return str(self._balance)

if __name__ == '__main__':
    eco = TomoRewardEconomy(1000)
    eco.set_rate('season', 1.25)
    eco.accrue(500)
    print(f'Initial Balance: {eco.get_value()}')
    print(f'Serialized: {eco.serialize()}')