from pathlib import Path


def test_login_endpoint_uses_jwt_auth_login() -> None:
    auth_route = Path('Code/API/routes/auth.py').read_text(encoding='utf-8')

    assert 'jwt_auth.login(' in auth_route
    assert 'send_token_as_response_body=True' in auth_route
    assert 'jwt_auth.create_token(' not in auth_route
