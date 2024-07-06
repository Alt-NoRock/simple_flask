const token = location.hash.split('=')[1];
alert('/report#flag=' + token);
location.href = '/flag?value=' + token;
