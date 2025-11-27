const request = require('supertest');
const app = require('../index');

describe('Joon Backend API Tests', () => {
  it('GET / should return 200 OK', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toEqual(200);
  });
});
