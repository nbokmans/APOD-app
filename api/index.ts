import express from 'express';
import { getApodData } from './util/apodApi';

const app = express();
const port = 8080;

app.get('/', (req, res) => {
    res.send('Hello world!');
});

app.get('/apod/:date?', async (req, res) => {
    const { date = '' } = req.params;
    const result = await getApodData({
        mode: 'day',
        date
    });

    res.send(result);
});

app.listen(port, () => {
    console.log(`server started at http://localhost:${port}`);
});