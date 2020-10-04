quicksort = (array) ->

  # Utility - swap the values at two indexes, but only if the values are different.
  swap = (index_0, index_1) ->
    [val_0, val_1] = [array[index_0], array[index_1]]
    [array[index_0], array[index_1]] = [val_1, val_0] unless val_0 == val_1

  # Divide a subset of the array (values between left and right, inclusive) into two partitions based on whether 
  # the elements are bigger or smaller than the value at the pivot index. Return the last index of the first partition.
  partition = (left, right, pivot_idx) ->
    pivot_val = array[pivot_idx]

    # Swap the pivot with the last element. We'll keep it there to be out of the way.
    swap pivot_idx, right

    # Walk through the array left to right and right to left until the indexes meet.
    # When we find things we want to be on the opposite side of the pivot, we swap them.
    left_idx = left
    right_idx = right - 1
    while (left_idx < right_idx)

      # Kinda lame because we access these every time through the loop, even when they haven't changed. It's slightly
      # awkward to fix, so without profiler results, I'm not gonna.
      left_val = array[left_idx]
      right_val = array[right_idx]

      # If both the current left and current right elements are on the wrong side, swap them.
      if left_val >= pivot_val && right_val < pivot_val
        [array[left_idx], array[right_idx]] = [right_val, left_val]
        left_idx += 1
        right_idx -= 1

      # Otherwise, check if on both indexes and see if their values are on the right side, and if so, advance them.
      # If they can't advance, it's because they're waiting for the other index to find something it wants to swap.
      else 
        left_idx += 1 if left_val < pivot_val
        right_idx -= 1 if right_val >= pivot_val

    # Swap the partition back in place where the two pointers met. The element the left index points to might be bigger
    # than the pivot (never had a chance to swap), so we may have to swap with the element to its right.
    swap_back = if array[left_idx] < pivot_val then left_idx + 1 else left_idx
    swap swap_back, right

    # Return the boundary between the two partitions
    swap_back

  # The main recursive function. We're going to sort the list into two buckets, such that all the elements in bucket
  # A are smaller than the elements in bucket B, and then sort the buckets. When the buckets reach size one, we're done.
  sort = (left, right) ->
    # Size-1 partitions are done
    return if left >= right

    # Pick a random pivot
    pivot_idx = Math.floor(Math.random() * (right - left + 1)) + left

    # Don't bother sub-partitioning if there are just two elements.
    # We just swap them directly if we need to, which saves us some silly swaps.
    if right - left == 1
      swap left, right if array[right] < array[left]
    else
      # Divide into partitions.
      split = partition left, right, pivot_idx

      # Sort each partition recursively.
      sort left, split
      sort split + 1, right

  # Sort the whole array.
  sort 0, array.length - 1

a = [27, 8, 6, 5, 8, 8, 19, 2, 3, 62, 2020, 62, 2, 43, 23, 1, 99, 2]
console.log "Sorting: #{a}"
quicksort a
console.log "Result: #{a}"
