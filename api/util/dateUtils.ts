import { parse } from 'date-fns';

export const parseNoOffset: (date: string | Date) => Date = (date) => {
    let parsedDate = date instanceof Date
        ? date
        : parse(date, 'yyyy-MM-dd', new Date());

    if (isNaN(parsedDate.getTime())) {
        parsedDate = new Date();
    }

    const utcOffset = parsedDate.getTimezoneOffset() * 60000;
    parsedDate = new Date(parsedDate.getTime() - utcOffset);
    return parsedDate;
}