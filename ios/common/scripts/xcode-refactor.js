const fs = require('fs');
const path = require('path');

const DIRECTORIES = ['BackgroundGeolocation', 'BackgroundGeolocationTests'];
const PBX_PROJ = path.join('BackgroundGeolocation.xcodeproj', 'project.pbxproj');
const PREFIX = 'MAUR';
const FILENAME_INCLUDE_CRITERIA = [
    /\.h$/,
    /\.m$/,
];
const FILENAME_EXCLUDE_CRITERIA = [
    RegExp(`^${PREFIX}`), // file is already prefixed
    /^(?=[A-Z]{2,})((?!SQL)).*/, //match leading 2 capital letters except SQL
    /^Reachability/,
    /^CocoaLumberjack/,
    /^Util/
];
const IMPORT_REGEXP = /\s*#import\s?\"(\w+\.[a-z]?)\"/g;

// https://stackoverflow.com/a/6969486/3896616
function escapeRegExp(str) {
  return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
}

let files = [].concat.apply([], DIRECTORIES.map(dir => fs.readdirSync(dir)
    .filter(fileName => {
        if (!FILENAME_INCLUDE_CRITERIA.some(regexp => regexp.test(fileName))) {
            return false;
        }
        if (!FILENAME_EXCLUDE_CRITERIA.some(regexp => regexp.test(fileName))) {
            return true;
        }
        return false;
    })
    .map(fileName => [dir, fileName])
));

const refactorTable = files.reduce((memo, [dir, fileName]) => {
    memo[fileName] = `${PREFIX}${fileName}`;
    return memo;
}, {});

const objInstances = Object.entries(refactorTable).reduce((memo, [fileName, newFileName]) => {
    const [instanceName] = fileName.split('.');
    const [newInstanceName] = newFileName.split('.');
    memo[instanceName] = newInstanceName;
    return memo;
}, {});

const ref = files.map(([dir, fileName]) => {
    let matches;
    const imports = [];
    const [file, extension = ''] = fileName.split('.');
    const fileComment = extension ? `${file}_${extension}` : file;
    const oldPath = path.join(dir, fileName);
    const newPath = path.join(dir, refactorTable[fileName]);
    let content = fs.readFileSync(oldPath, 'utf8');

    // log imports to be returned from function
    while ((matches = IMPORT_REGEXP.exec(content)) !== null) {
        const [match, p1] = matches;
        imports.push(p1);
    }

    // replace imports
    content = content.replace(IMPORT_REGEXP, (match, fileName) => {
        const beginIndex = match.indexOf(fileName);
        const begin = match.substring(0, beginIndex);
        const end = match.substring(beginIndex + fileName.length);
        const refactoredFileName = refactorTable[fileName] || fileName;
        return `${begin}${refactoredFileName}${end}`;
    });

    /*
       replace class name in comment
       eg:
       //  BackgroundGeolocationFacade.h
    */
    content = content.replace(RegExp(`\/\/\\s*(${escapeRegExp(fileName)})`), (match, p1) => {
        const beginIndex = match.indexOf(p1);
        const begin = match.substring(0, beginIndex);
        const end = match.substring(beginIndex + p1.length);
        return `${begin}${PREFIX}${p1}${end}`;
    });

    // replace ifdefs and ifndef
    content = content.replace(RegExp(`#ifndef\\s*(${escapeRegExp(fileComment)})`), (match, p1) => {
        const beginIndex = match.indexOf(p1);
        const begin = match.substring(0, beginIndex);
        const end = match.substring(beginIndex + p1.length);
        return `${begin}${PREFIX}${p1}${end}`;
    });

    // replace define
    content = content.replace(RegExp(`#define\\s*(${escapeRegExp(fileComment)})`), (match, p1) => {
        const beginIndex = match.indexOf(p1);
        const begin = match.substring(0, beginIndex);
        const end = match.substring(beginIndex + p1.length);
        return `${begin}${PREFIX}${p1}${end}`;
    });

    // replace endif
    content = content.replace(RegExp(`#endif\\s*\\/\\*\\s*(${escapeRegExp(fileComment)})\\s*\\*\\/`), (match, p1) => {
        const beginIndex = match.indexOf(p1);
        const begin = match.substring(0, beginIndex);
        const end = match.substring(beginIndex + p1.length);
        return `${begin}${PREFIX}${p1}${end}`;
    });

    // replace interface
    content = content.replace(RegExp(`\\s*@interface\\s*(${escapeRegExp(file)})\\s*(:\\s*(\\w+)(<\\w+>)?)?`), (match, p1, p2, p3) => {
        if (p3) {
            const beginIndex = match.indexOf(p1);
            const begin = match.substring(0, beginIndex);
            const protocolIndex = match.indexOf(p3);
            const end = match.substring(protocolIndex + p3.length);
            return [
                `${begin}${PREFIX}${p1}`,
                `${match.substring(beginIndex + p1.length, protocolIndex)}`,
                `${objInstances[p3]||p3}`,
                `${end}`
            ].join('');
        } else {
            const beginIndex = match.indexOf(p1);
            const begin = match.substring(0, beginIndex);
            const end = match.substring(beginIndex + p1.length);    
            return `${begin}${PREFIX}${p1}${end}`;
        }
    });

    // replace implementation
    // TODO: replace protocol too
    content = content.replace(RegExp(`\\s*@implementation\\s*(${escapeRegExp(file)})`), (match, p1) => {
        let beginIndex = match.indexOf(p1);
        let begin = match.substring(0, beginIndex);
        let end = match.substring(beginIndex + p1.length);
        return `${begin}${PREFIX}${p1}${end}`;
    });

    // replace vars
    Object.entries(objInstances).forEach(([oldName, newName]) => {
        content = content.replace(RegExp(`\\b(${escapeRegExp(oldName)})\\s*(<\\w+>)?\\s*\\*`, 'g'), (match, p1) => {
            const beginIndex = match.indexOf(p1);
            const begin = match.substring(0, beginIndex);
            const end = match.substring(beginIndex + p1.length);
            return `${begin}${newName}${end}`;
        });    
    });

    // replace static method calls
    Object.entries(objInstances).forEach(([oldName, newName]) => {
        content = content.replace(RegExp(`\\[(${escapeRegExp(oldName)})\\s+.*\\]`, 'g'), (match, p1) => {
            const beginIndex = match.indexOf(p1);
            const begin = match.substring(0, beginIndex);
            const end = match.substring(beginIndex + p1.length);
            return `${begin}${newName}${end}`;
        });    
    });

    fs.renameSync(oldPath, newPath);
    fs.writeFileSync(newPath, content);

    return {
        oldPath,
        newPath,
        imports,
        newImports: imports.map(imp => refactorTable[imp]||imp)
    }
});

let pbxProj = fs.readFileSync(PBX_PROJ, 'utf8');
Object.keys(refactorTable).forEach(fileName => {
    pbxProj = pbxProj.replace(RegExp(`\\b(${escapeRegExp(fileName)})`, 'g'), (match, fileName) => {
        const beginIndex = match.indexOf(fileName);
        const begin = match.substring(0, beginIndex);
        const end = match.substring(beginIndex + fileName.length);
        const refactoredFileName = refactorTable[fileName];
        return `${begin}${refactoredFileName}${end}`;
    });
});

fs.writeFileSync(PBX_PROJ, pbxProj);

console.log(ref);