import fetch from 'node-fetch';
import { format, sub, add, startOfWeek } from 'date-fns';
import { JSDOM } from 'jsdom';
import { parseNoOffset } from './dateUtils';

const APOD_BASE_URL = 'https://apod.nasa.gov/apod'
const DEFAULT_APOD_OPTIONS: FetchApodDataOptions = {
    mode: 'day',
    date: new Date()
}

export interface APODAuthor {
    name: string;
    website: string;
}

export interface APODResult {
    date: Date;
    image?: string;
    fullSizeImage?: string;
    authors?: APODAuthor[];
    name?: string;
    description?: string;
}

export interface FetchApodDataOptions {
    date?: Date | string;
    mode?: 'day' | 'week';
}

export const getApodData: (options?: FetchApodDataOptions) => Promise<APODResult[]> = async (options = DEFAULT_APOD_OPTIONS) => {
    const finalOptions = {
        ...DEFAULT_APOD_OPTIONS,
        ...options
    };

    let dates: Date[] = [];
    const parsedStartDate = parseNoOffset(options.date);

    switch (finalOptions.mode) {
        case 'day': {
            dates = [parsedStartDate];
            break;
        }
        case 'week': {
            const prevWeekStartDate = sub(startOfWeek(parsedStartDate), { days: 7 });
            dates = Array.from(Array(7)).map((_, n) => add(prevWeekStartDate, { days: n }));
            break;
        }
    }

    return scrapeApod(dates);
}

const formatUrl = (endpoint?: string) => `${APOD_BASE_URL}/${endpoint}`;

const scrapeApod: (dates: Date[]) => Promise<APODResult[]> = async (dates: Date[]) => {
    const requests = dates.map(async (date: Date) => {
        const formattedDate = format(date, 'yyMMdd');
        const res = await fetch(formatUrl(`/ap${formattedDate}.html`));
        const body = await res.text();
        const dom = new JSDOM(body);
        const doc = dom.window.document;

        const description = doc.querySelector('body > p:nth-of-type(1)').textContent?.replace(/\r?\n|\r/g, '').trim();
        const authors: APODAuthor[] = Array.from(doc.querySelectorAll('center:nth-of-type(2) a'))
            ?.map((elem: HTMLAnchorElement) => ({
                name: elem.textContent,
                website: elem.href,
            })) ?? [];

        const imgAnchor = doc.querySelector('center:nth-of-type(1) p:nth-of-type(2)')?.children[1] as HTMLAnchorElement;
        const fullSizeImage = formatUrl(imgAnchor?.href);
        const image = formatUrl((imgAnchor?.children[0] as HTMLImageElement)?.src);

        return {
            date,
            image,
            fullSizeImage,
            authors,
            description
        };
    });

    const results = await Promise.all(requests);
    return results;
}