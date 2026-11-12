import pandas as pd

left = pd.DataFrame({
    'key': pd.Series(['a', None, 'b'], dtype='string[pyarrow]'),
    'left': [1, 2, 3],
})
right = pd.DataFrame({
    'key': pd.Series(['b', None], dtype='string[pyarrow]'),
    'right': [30, 20],
})
for how in ['inner', 'left', 'right', 'outer']:
    for sort in [False, True]:
        result = left.merge(right, on='key', how=how, sort=sort)
        expected = left.astype({'key': object}).merge(
            right.astype({'key': object}), on='key', how=how, sort=sort)
        pd.testing.assert_frame_equal(
            result.astype({'key': object}), expected, check_dtype=False)
print('PASS: nullable Arrow string joins, four join modes, sorted and unsorted')
