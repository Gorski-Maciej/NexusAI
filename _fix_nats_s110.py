#!/usr/bin/env python3
"""Fix S110 in nats_utils.py - add logger.debug to except:pass blocks."""
import re

with open("nexus_ai/core/nats_utils.py", "r") as f:
    content = f.read()

fixes = []

# Fix 1: Line 85 - except (ImportError, AttributeError): pass
old = "except (ImportError, AttributeError):\n            pass"
new = "except (ImportError, AttributeError):\n            logger.debug(\"[NATS] Error types import failed\")\n            pass"
if old in content:
    content = content.replace(old, new)
    fixes.append("NatsErrors.init: added logging")

# Fix 2: Line 125 - flush exception
old = """            try: await nc.flush()
            except Exception: pass"""
new = """            try: await nc.flush()
            except Exception:\n                logger.debug(\"[NATS] Flush failed during close\")\n                pass"""
if old in content:
    content = content.replace(old, new)
    fixes.append("safe_close flush: added logging")

# Fix 3: Line 129 - close exception
old = """        try: await nc.close()
        except Exception: pass"""
new = """        try: await nc.close()
        except Exception:\n            logger.debug(\"[NATS] Close failed during drain fallback\")\n            pass"""
if old in content:
    content = content.replace(old, new)
    fixes.append("safe_close fallback: added logging")

# Fix 4: Line 181 - ensure_connected ping exception
old = """            try: await self._nc.ping(); return True
            except Exception: pass"""
new = """            try: await self._nc.ping(); return True
            except Exception:\n                logger.debug(\"[NATS:RPC] Ping failed, reconnecting\")\n                pass"""
if old in content:
    content = content.replace(old, new)
    fixes.append("ensure_connected ping: added logging")

# Fix 5: Line 201 - msgspec.json.decode exception
old = """            try: return msgspec.json.decode(msg.data)
            except Exception:"""
new = """            try: return msgspec.json.decode(msg.data)
            except Exception:\n                logger.debug(\"[NATS:RPC] msgspec.json.decode failed, trying fallback\")\n                pass"""
if old in content:
    content = content.replace(old, new)
    fixes.append("rpc decode json: added logging")

# Fix 6: Line 204 - _msgspec_loads exception
old = """                try: return _msgspec_loads(msg.data)
                except Exception: return msg.data"""
new = """                try: return _msgspec_loads(msg.data)
                except Exception:\n                    logger.debug(\"[NATS:RPC] Both decoders failed, returning raw data\")\n                    return msg.data"""
if old in content:
    content = content.replace(old, new)
    fixes.append("rpc decode fallback: added logging")

# Fix 7: Line 239 - unsubscribe exception
old = """            try: await self._sub.unsubscribe()
            except Exception: pass"""
new = """            try: await self._sub.unsubscribe()
            except Exception:\n                logger.debug(\"[NATS:SUB] Unsubscribe failed\")\n                pass"""
if old in content:
    content = content.replace(old, new)
    fixes.append("subscription unsubscribe: added logging")

# Fix 8: Line 248 - NatsConfigStore create_key_value exception
old = """                    self._kv_stores[name] = await self._js.create_key_value(bucket=name, description=desc, history=5, max_value_size=1024*1024)
                except Exception:
                    pass"""
new = """                    self._kv_stores[name] = await self._js.create_key_value(bucket=name, description=desc, history=5, max_value_size=1024*1024)
                except Exception:
                    logger.debug(\"[KV] Create bucket '%s' failed\", name)
                    pass"""
if old in content:
    content = content.replace(old, new)
    fixes.append("kv create bucket: added logging")

# Fix 9: Line 265 - drain exception in stop
old = """            try: await self._nc.drain()
            except Exception: pass"""
new = """            try: await self._nc.drain()
            except Exception:\n                logger.debug(\"[KV] Drain failed during stop\")\n                pass"""
if old in content:
    content = content.replace(old, new)
    fixes.append("kv stop drain: added logging")

# Fix 10: Line 270 - put exception
old = """            try: await kv.put(key, msgspec_dumps_bytes(value)); return True
            except Exception: pass"""
new = """            try: await kv.put(key, msgspec_dumps_bytes(value)); return True
            except Exception:\n                logger.debug(\"[KV] Put '%s' failed\", key)\n                pass"""
if old in content:
    content = content.replace(old, new)
    fixes.append("kv put: added logging")

# Fix 11: Line 276 - get exception
old = """                    return _msgspec_loads(entry.value)
            except Exception: pass"""
new = """                    return _msgspec_loads(entry.value)
            except Exception:\n                logger.debug(\"[KV] Get '%s' failed\", key)\n                pass"""
if old in content:
    content = content.replace(old, new)
    fixes.append("kv get: added logging")

# Fix 12: Line 282 - delete exception
old = """            try: await kv.delete(key); return True
            except Exception: pass"""
new = """            try: await kv.delete(key); return True
            except Exception:\n                logger.debug(\"[KV] Delete '%s' failed\", key)\n                pass"""
if old in content:
    content = content.replace(old, new)
    fixes.append("kv delete: added logging")

# Fix 13: Line 338 - create_object_store exception
old = """                try: self._object_stores[name] = await self._js.create_object_store(bucket=name, description=desc, max_age=365*86400, storage=\"file\")
                except Exception: pass"""
new = """                try: self._object_stores[name] = await self._js.create_object_store(bucket=name, description=desc, max_age=365*86400, storage=\"file\")
                except Exception:\n                    logger.debug(\"[OBJECT] Create bucket '%s' failed\", name)\n                    pass"""
if old in content:
    content = content.replace(old, new)
    fixes.append("object store create bucket: added logging")

# Fix 14: Line 346 - drain exception in object stop
old = """            try: await self._nc.drain()
            except Exception: pass"""
new = """            try: await self._nc.drain()
            except Exception:\n                logger.debug(\"[OBJECT] Drain failed during stop\")\n                pass"""
if old in content:
    content = content.replace(old, new)
    fixes.append("object stop drain: added logging")

# Fix 15: Line 358 - object put exception
old = """                return {\"name\": key, \"size\": len(data), \"bucket\": bucket}
            except Exception: pass"""
new = """                return {\"name\": key, \"size\": len(data), \"bucket\": bucket}
            except Exception:\n                logger.debug(\"[OBJECT] Put '%s' failed\", key)\n                pass"""
if old in content:
    content = content.replace(old, new)
    fixes.append("object put: added logging")

# Fix 16: Line 368 - object get exception
old = """                    return (data if isinstance(data, bytes) else data.read()), {\"name\": key, \"bucket\": bucket}
            except Exception: pass"""
new = """                    return (data if isinstance(data, bytes) else data.read()), {\"name\": key, \"bucket\": bucket}
            except Exception:\n                logger.debug(\"[OBJECT] Get '%s' failed\", key)\n                pass"""
if old in content:
    content = content.replace(old, new)
    fixes.append("object get: added logging")

# Fix 17: Line 380 - object delete exception
old = """            try: await obj.delete(key); return True
            except Exception: pass"""
new = """            try: await obj.delete(key); return True
            except Exception:\n                logger.debug(\"[OBJECT] Delete '%s' failed\", key)\n                pass"""
if old in content:
    content = content.replace(old, new)
    fixes.append("object delete: added logging")

# Fix 18: Line 425 - get_streams outer exception
old = """        except Exception: pass"""
new = """        except Exception:\n            logger.debug(\"[NATS:SUPERVISOR] get_streams failed\")\n            pass"""
if old in content:
    content = content.replace(old, new)
    fixes.append("supervisor get_streams: added logging")

# Fix 19: Line 449 - stop drain exception
old = """            try: await self._nc.drain()
            except Exception: pass"""
new = """            try: await self._nc.drain()
            except Exception:\n                logger.debug(\"[NATS:SUPERVISOR] Drain failed during stop\")\n                pass"""
if old in content:
    content = content.replace(old, new)
    fixes.append("supervisor stop drain: added logging")

with open("nexus_ai/core/nats_utils.py", "w") as f:
    f.write(content)

print(f"Applied {len(fixes)} S110 fixes:")
for f in fixes:
    print(f"  - {f}")

import ast
try:
    ast.parse(content)
    print("\nSYNTAX OK!")
except SyntaxError as e:
    print(f"\nSyntaxError at line {e.lineno}: {e.msg}")
