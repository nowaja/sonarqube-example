<?php declare(strict_types=1);

namespace App\Repository;

final class DataRepository implements DataRepositoryInterface
{
    public function insert(array $dataToInsert): bool
    {
        return true;
    }

    public function findAll(): array
    {
        return ['data'];
    }

    public function getNewestDate(): \DateTime
    {
        return new \DateTime();
    }
}
