from typing import Any, Generic, Optional, TypeVar

from pydantic import BaseModel, ConfigDict, Field

T = TypeVar("T")


class ORMModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)


class APIMessage(BaseModel):
    ok: bool = True
    message: str
    message_spoken: dict[str, str] = Field(default_factory=dict)


class Envelope(BaseModel, Generic[T]):
    ok: bool = True
    data: T
    message: Optional[str] = None
    message_spoken: dict[str, str] = Field(default_factory=dict)


class ErrorBody(BaseModel):
    error: bool = True
    code: str
    message: str
    message_spoken: dict[str, str] = Field(default_factory=dict)
    details: dict[str, Any] = Field(default_factory=dict)
