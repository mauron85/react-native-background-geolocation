//import { promisify } from './es6-promisify';
import BackgroundGeolocation from 'react-native-mauron85-background-geolocation';

function promisify(func) {
    return (...args) => {
        return new Promise((resolve, reject) => {
            const success = (data) => resolve(data);
            const failure = (err) => reject(err);
            func.apply(func, [success, failure, ...args]);
        });
    };
}

const EXCLUDES = ['on'];

for (var propName in BackgroundGeolocation) {
    const prop = BackgroundGeolocation[propName];
    if (typeof prop === 'function' && !~EXCLUDES.indexOf(propName)) {
        BackgroundGeolocation[propName + 'Async'] = promisify(prop);
    }
}


export { BackgroundGeolocation };
