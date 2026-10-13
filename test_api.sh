
# Get token
TOKEN=$(curl -s -X POST http://127.0.0.1:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@volo.kz", "password": "admin"}' | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])")

echo "Token: $TOKEN"

echo "Testing /users/me..."
curl -s -o /dev/null -w "%{http_code}\n" -X GET http://127.0.0.1:8080/users/me -H "Authorization: Bearer $TOKEN"

echo "Testing /events/my-events..."
curl -s -o /dev/null -w "%{http_code}\n" -X GET http://127.0.0.1:8080/events/my-events -H "Authorization: Bearer $TOKEN"

echo "Testing /events/..."
curl -s -o /dev/null -w "%{http_code}\n" -X GET http://127.0.0.1:8080/events/ -H "Authorization: Bearer $TOKEN"
Testing /events/my-applications...
curl -s -X GET http://127.0.0.1:8080/events/my-applications -H "Authorization: Bearer $TOKEN"
